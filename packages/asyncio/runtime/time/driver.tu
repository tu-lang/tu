// Time driver: thin wrapper that hands the IO driver a max-park timeout
// derived from the wheel and advances the wheel after each turn().

use runtime
use sys
use io
use asyncio.runtime.io as rtio
use asyncio.task as task

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

    LAST_TIMEDRIVER = drv
    LAST_TIMEHANDLE = h
    return 0
}

// Cross-pkg factory — callers must not write rttime.TimeDriver::new(...).
fn time_driver_new(park_iod<rtio.IoDriver>) i32 {
    return TimeDriver::new(park_iod)
}

// Compute the effective max-wait for the IO driver: min(limit, time to
// next deadline). Called with the handle lock held by park_internal.
fn compute_effective_ms(handle<TimeHandle>, limit_ms<u64>) u64 {
    found<i32>, deadline<u64> = handle.wheel.poll_at()
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
// performed outside the wheel lock to avoid waker re-entry.
TimeHandle::process(now_ms<u64>){
    this.lock.lock()
    this.wheel.poll(now_ms)
    pending<EntryList> = this.wheel.take_pending()
    this.lock.unlock()

    // Mem null compares are unreliable — drain while front_bits != 0.
    loop {
        if pending.front_bits == 0 {
            break
        }
        cur<TimerShared> = pending.pop_front()
        cbits<u64> = 0
        cbits = cur
        if cbits == 0 {
            break
        }
        s<StateCell> = cur.get_cell()
        s.mark_pending(now_ms)
        wake_ctx<u64> = s.take_waker_ctx()
        if wake_ctx != 0 {
            task.wake_by_ctx(wake_ctx)
        }
    }
}

// Park the IO driver up to `limit_ms`, but no longer than the next wheel
// deadline. Computes the timeout first, then process() after the turn.
TimeDriver::park_internal(handle<TimeHandle>, limit_ms<u64>, ioh<rtio.IoHandle>) i32 {
    handle.lock.lock()
    eff_ms<u64> = compute_effective_ms(handle, limit_ms)
    handle.lock.unlock()

    if this.park_iod == null || ioh == null {
        // No IO park path: advance the wheel, then yield briefly.
        handle.process(handle.now_ms())
        runtime.osyield()
        return 0
    }

    iod<rtio.IoDriver> = this.park_iod
    err<i32> = iod.turn(ioh, ms_to_duration(eff_ms))
    handle.process(handle.now_ms())
    return err
}

// Schedule an entry. Returns INSERT_* from Wheel::insert.
TimeHandle::register(entry<TimerEntry>) i32 {
    this.lock.lock()
    err<i32>, deadline<u64> = this.wheel.insert(entry.shared, entry.deadline_ms)
    if err == INSERT_OK {
        entry.registered = 1
    } else if err == INSERT_ELAPSED {
        // mark_pending leaves PENDING_FIRE so poll_elapsed returns FIRED
        // on this same Sleep::poll (waker optional — caller is polling now).
        s<StateCell> = entry.shared.get_cell()
        s.mark_pending(deadline)
        entry.registered = 1
    }
    this.lock.unlock()
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
