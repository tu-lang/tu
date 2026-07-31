// Time driver: next_wake + single turn(eff) + drive_wheel.
// MT: absorb pure eventfd wakeups inside park (early re-poll SEGVs).

use runtime
use sys
use io
use std
use asyncio.runtime.io as rtio
use asyncio.task as task

// Bounded nanosleep slice when IO park is unavailable (time-only MT).
PARK_SLICE_MS<u64> = 50

// Driver-side state. wheel + clk are owned here; park_iod is borrowed
// from the runtime's IoDriver so park_internal can delegate.
// Field is `clk` (not `clock`) — `.clock` is a type-assert trap.
mem TimeDriver {
    Wheel*          wheel
    TimeSource*     source
    Clock*          clk
    rtio.IoDriver*  park_iod      // borrowed; null when IO driver disabled
}

// Cross-thread companion. Anything that schedules a timer touches the
// wheel through TimeHandle.
mem TimeHandle {
    TimeSource*         source
    runtime.MutexInter* lock     // serialises wheel mutations
    Wheel*              wheel
    Clock*              clk      // not `clock` — type-assert trap
    u64                 next_wake_ms   // absolute ms; 0 = none published
    u64                 ioh_wake_bits  // IoHandle eventfd for insert-wake
}

// Last successful TimeDriver::new results. build_drivers uses last()
// getters — (TimeDriver, TimeHandle) dual-ret drops park_iod (same trap as
 // IoDriver / SignalDriver).
LAST_TIMEDRIVER<TimeDriver> = null
LAST_TIMEHANDLE<TimeHandle> = null

fn timedriver_last() TimeDriver {
    return LAST_TIMEDRIVER
}
fn timehandle_last() TimeHandle {
    return LAST_TIMEHANDLE
}

// Safe clock read — avoid `.clock` / chained field traps.
TimeHandle::now_ms() u64 {
    c<Clock> = this.clk
    if c == null return 0
    return c.now_ms()
}

// Wire IoHandle eventfd so a sooner deadline can unpark the reactor.
fn time_handle_bind_ioh_bits(handle_bits<u64>, ioh_bits<u64>) {
    if handle_bits == 0 {
        return
    }
    th<TimeHandle> = handle_bits
    th.ioh_wake_bits = ioh_bits
}

// Build a paired (driver, handle). Publishes via timedriver_last / timehandle_last.
const TimeDriver::new(park_iod<rtio.IoDriver>) i32 {
    LAST_TIMEDRIVER = null
    LAST_TIMEHANDLE = null

    src<TimeSource> = TimeSource::new()
    w<Wheel>        = Wheel::new()
    c<Clock>        = Clock::new(src)

    drv<TimeDriver> = new TimeDriver
    drv.wheel    = w
    drv.source   = src
    drv.clk      = c
    drv.park_iod = park_iod

    h<TimeHandle> = new TimeHandle
    h.source = src
    h.lock = new runtime.MutexInter
    h.lock.init()
    h.wheel = w
    h.clk = c
    h.next_wake_ms = 0
    h.ioh_wake_bits = 0

    LAST_TIMEDRIVER = drv
    LAST_TIMEHANDLE = h
    return 0
}

// Cross-pkg factory bridge. `rttime.TimeDriver::new` also works when typed.
fn time_driver_new(park_iod<rtio.IoDriver>) i32 {
    return TimeDriver::new(park_iod)
}

// Compute the effective max-wait for the IO driver: min(limit, time to
// next deadline). Holds the handle lock while reading the wheel.
fn compute_effective_ms(handle<TimeHandle>, limit_ms<u64>) u64 {
    handle.lock.lock()
    found<i32>, deadline<u64> = handle.wheel.poll_at()
    handle.lock.unlock()
    if found != EXPIR_FOUND return limit_ms
    now_ms<u64> = handle.now_ms()
    if deadline <= now_ms return 0
    delta<u64> = deadline - now_ms
    if delta > limit_ms return limit_ms
    return delta
}

// Convert ms to sys.Duration.
fn ms_to_duration(ms<u64>) sys.Duration {
    return sys.Duration::from_millis(ms)
}

// Advance the wheel up to `now` and wake every fired timer. Wakes are
// performed outside any wheel lock to avoid waker re-entry.
TimeHandle::drive_wheel(now_ms<u64>){
    // Named drive_wheel — `.process` is a type-assert trap.
    this.lock.lock()
    this.wheel.poll(now_ms)
    pending<EntryList> = this.wheel.take_pending()
    found<i32>, deadline<u64> = this.wheel.poll_at()
    if found != EXPIR_FOUND {
        this.next_wake_ms = 0
    } else {
        this.next_wake_ms = deadline
    }
    this.lock.unlock()

    // Drain fired entries; pop_front() returns null when the list is empty.
    loop {
        cur<TimerShared> = pending.pop_front()
        if cur == null {
            break
        }
        s<StateCell> = cur.get_cell()
        if s == null {
            continue
        }
        s.mark_pending(now_ms)
        wake_ctx<u64> = s.take_waker_ctx()
        if wake_ctx != 0 {
            task.wake_by_ctx(wake_ctx)
        }
    }
}

// Park up to limit_ms, narrowed by the next wheel deadline.
// Mother: publish next_wake → one IoDriver::turn(eff) → drive_wheel.
// Blocking epoll is GC-safe via entersyscall (stack scanned at syscall_sp).
TimeDriver::park_internal(handle<TimeHandle>, limit_ms<u64>, ioh<rtio.IoHandle>) i32 {
    eff_ms<u64> = compute_effective_ms(handle, limit_ms)
    handle.lock.lock()
    found0<i32>, deadline0<u64> = handle.wheel.poll_at()
    if found0 != EXPIR_FOUND {
        handle.next_wake_ms = 0
    } else {
        handle.next_wake_ms = deadline0
    }
    handle.lock.unlock()

    if this.park_iod == null || ioh == null {
        // Time-only: advance wheel, then nanosleep up to next deadline.
        now<u64> = handle.now_ms()
        handle.drive_wheel(now)
        handle.lock.lock()
        found_t<i32>, deadline_t<u64> = handle.wheel.poll_at()
        if found_t != EXPIR_FOUND {
            handle.next_wake_ms = 0
        } else {
            handle.next_wake_ms = deadline_t
        }
        handle.lock.unlock()
        if found_t != EXPIR_FOUND {
            // Empty wheel: brief sleep so JoinHandle unpark can land; never
            // sleep the full park limit (select short vs long would both Ready).
            eff_ms = 1
        } else {
            now_t<u64> = handle.now_ms()
            if deadline_t <= now_t {
                eff_ms = 1
            } else {
                delta_t<u64> = deadline_t - now_t
                eff_ms = limit_ms
                if delta_t < eff_ms {
                    eff_ms = delta_t
                }
                if eff_ms > PARK_SLICE_MS {
                    eff_ms = PARK_SLICE_MS
                }
                if eff_ms == 0 {
                    eff_ms = 1
                }
            }
        }
        req<std.TimeSpec:> = null
        rem<std.TimeSpec:> = null
        req.sec = 0
        nsec_v<u64> = eff_ms * 1000000
        req.nsec = nsec_v.(i64)
        runtime.entersyscall()
        std.nanosleep(&req, &rem)
        runtime.exitsyscall()
        handle.drive_wheel(handle.now_ms())
        return 0
    }

    iod<rtio.IoDriver> = this.park_iod
    // Mother: one turn(eff) then process. Pure eventfd wakeups (insert-wake /
    // unpark) must not return to MT block_on re-poll — that path SEGVs.
    // Retry until a timer fires, IO hits, or the wheel is empty.
    err<i32> = 0
    loops<i32> = 0
    loop {
        if loops > 64 {
            break
        }
        loops += 1
        handle.lock.lock()
        found_l<i32>, deadline_l<u64> = handle.wheel.poll_at()
        if found_l != EXPIR_FOUND {
            handle.next_wake_ms = 0
        } else {
            handle.next_wake_ms = deadline_l
        }
        handle.lock.unlock()

        if found_l != EXPIR_FOUND {
            err = iod.turn(ioh, ms_to_duration(1))
            handle.drive_wheel(handle.now_ms())
            break
        }
        now_l<u64> = handle.now_ms()
        if deadline_l <= now_l {
            err = iod.turn(ioh, ms_to_duration(0))
            handle.drive_wheel(handle.now_ms())
            break
        }
        delta_l<u64> = deadline_l - now_l
        wait_l<u64> = limit_ms
        if delta_l < wait_l {
            wait_l = delta_l
        }
        if wait_l == 0 {
            wait_l = 1
        }
        err = iod.turn(ioh, ms_to_duration(wait_l))
        handle.drive_wheel(handle.now_ms())
        if rtio.iodriver_took_io(iod) != 0 {
            break
        }
        handle.lock.lock()
        found2<i32>, dl2<u64> = handle.wheel.poll_at()
        handle.lock.unlock()
        if found2 != EXPIR_FOUND {
            break
        }
        if dl2 != deadline_l {
            break
        }
    }
    return err
}

// Schedule an entry. Returns INSERT_* from Wheel::insert.
// If the new deadline is sooner than next_wake_ms, wake the IoHandle.
TimeHandle::register(entry<TimerEntry>) i32 {
    this.lock.lock()
    err<i32>, deadline<u64> = this.wheel.insert(entry.shared, entry.deadline_ms)
    need_wake<i32> = 0
    if err == INSERT_OK {
        entry.registered = 1
        nw<u64> = this.next_wake_ms
        if nw == 0 || deadline < nw {
            this.next_wake_ms = deadline
            need_wake = 1
        }
    } else if err == INSERT_ELAPSED {
        // mark_pending leaves PENDING_FIRE so poll_elapsed returns FIRED
        // on this same Sleep::poll (waker optional — caller is polling now).
        s<StateCell> = entry.shared.get_cell()
        s.mark_pending(deadline)
        entry.registered = 1
        need_wake = 1
    }
    wake_bits<u64> = this.ioh_wake_bits
    this.lock.unlock()
    if need_wake != 0 && wake_bits != 0 {
        rtio.io_handle_wake_bits(wake_bits)
    }
    return err
}

// Cross-pkg register: handle + entry as u64 bits.
fn time_handle_register_bits(handle_bits<u64>, entry_bits<u64>) i32 {
    if handle_bits == 0 return -1
    th<TimeHandle> = handle_bits
    e<TimerEntry> = entry_bits
    return th.register(e)
}

// Typed clock read used by the u64 bits bridge.
fn time_handle_now_ms(th<TimeHandle>) u64 {
    if th == null return 0
    return th.now_ms()
}

// Cross-pkg clock read: foreign packages must not chain th.clk.now_ms().
fn time_handle_now_ms_bits(handle_bits<u64>) u64 {
    if handle_bits == 0 return 0
    th<TimeHandle> = handle_bits
    return time_handle_now_ms(th)
}

// Cancel an entry. Safe to call on un-registered entries.
TimeHandle::cancel(entry<TimerEntry>){
    this.lock.lock()
    if entry.registered == 1 {
        this.wheel.remove(entry.shared)
        entry.registered = 0
    }
    this.lock.unlock()
    s<StateCell> = entry.shared.get_cell()
    s.deregister()
}
