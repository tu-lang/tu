// Time driver: thin wrapper that hands the IO driver a max-park timeout
// derived from the wheel and advances the wheel after each turn().

use runtime
use sys
use io

// Driver-side state. wheel + clock are owned here; io_park is borrowed
// from the runtime's IoDriver so park_internal can delegate.
mem TimeDriver {
    Wheel*       wheel
    TimeSource*  source
    Clock*       clock
    IoDriver*    io_park       // borrowed; null when IO driver disabled
}

// Cross-thread companion. Anything that schedules a timer touches the
// wheel through TimeHandle.
mem TimeHandle {
    TimeSource*       source
    runtime.MutexInter lock     // serialises wheel mutations
    Wheel*            wheel
    Clock*            clock
}

// Build a paired (driver, handle).
const TimeDriver::new(io_park<IoDriver>) (TimeDriver, TimeHandle) {
    src<TimeSource> = TimeSource::new()
    w<Wheel>        = Wheel::new()
    c<Clock>        = Clock::new(src)

    drv<TimeDriver> = new TimeDriver
    drv.wheel   = w
    drv.source  = src
    drv.clock   = c
    drv.io_park = io_park

    h<TimeHandle> = new TimeHandle
    h.source = src
    h.lock.init()
    h.wheel = w
    h.clock = c

    return drv, h
}

// Compute the effective max-wait for the IO driver: min(limit, time to
// next deadline). Called with the handle lock held by park_internal.
fn compute_effective_ms(handle<TimeHandle>, limit_ms<u64>) u64 {
    found<i32>, deadline<u64> = handle.wheel.poll_at()
    if found != EXPIR_FOUND return limit_ms
    now_ms<u64> = handle.clock.now_ms()
    if deadline <= now_ms return 0
    delta<u64> = deadline - now_ms
    if delta > limit_ms return limit_ms
    return delta
}

// Convert ms to sys.Duration (secs + nanos<u32>).
fn ms_to_duration(ms<u64>) sys.Duration {
    secs<u64> = ms / 1000
    rem<u64>  = ms % 1000
    nanos<u32> = (rem * 1000000).(u32)
    return new sys.Duration {
        secs:  secs,
        nanos: new sys.Nanoseconds { inner: nanos },
    }
}

// Advance the wheel up to `now` and wake every fired timer. Wakes are
// performed outside the wheel lock to avoid waker re-entry.
TimeHandle::process(now_ms<u64>){
    this.lock.lock()
    this.wheel.poll(now_ms)
    pending<EntryList> = this.wheel.take_pending()
    this.lock.unlock()

    cur<TimerShared> = pending.pop_front()
    while cur != null {
        s<StateCell> = cur.state
        s.mark_pending(now_ms)
        s.take_waker_ctx()
        // ctx_packed of the AtomicWaker is consumed by take_waker_ctx; the
        // caller layer will hand it to the scheduler once the runtime
        // root lands. For now we merely flip state to PENDING_FIRE so a
        // subsequent poll observes the result.
        cur = pending.pop_front()
    }
}

// Park the IO driver up to `limit_ms`, but no longer than the next wheel
// deadline. Returns whatever IoDriver::turn returned.
TimeDriver::park_internal(handle<TimeHandle>, limit_ms<u64>) i32 {
    handle.lock.lock()
    eff_ms<u64> = compute_effective_ms(handle, limit_ms)
    handle.lock.unlock()

    if this.io_park == null {
        // No IO driver: nothing to park on; return immediately and let
        // the scheduler run the next iteration.
        return 0
    }

    err<i32> = this.io_park.turn(this.io_park_handle_for(handle), ms_to_duration(eff_ms))
    handle.process(handle.clock.now_ms())
    return err
}

// Helper: surface whatever IoHandle the io_park driver is paired with.
// First-pass returns null because the runtime root has not wired the
// pair through yet; build_*_thread (Phase 10) will replace this.
TimeDriver::io_park_handle_for(handle<TimeHandle>) IoHandle {
    return null
}

// Schedule an entry. Returns INSERT_* from Wheel::insert.
TimeHandle::register(entry<TimerEntry>) i32 {
    this.lock.lock()
    err<i32>, deadline<u64> = this.wheel.insert(entry.shared, entry.deadline_ms)
    if err == 0 entry.registered = 1
    this.lock.unlock()
    return err
}

// Cancel an entry. Safe to call on un-registered entries.
TimeHandle::cancel(entry<TimerEntry>){
    this.lock.lock()
    if entry.registered == 1 {
        this.wheel.remove(entry.shared)
        entry.registered = 0
    }
    this.lock.unlock()
    s<StateCell> = entry.shared.state
    s.deregister()
}

