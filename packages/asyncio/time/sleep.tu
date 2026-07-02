// Sleep leaf future plus the package-level sleep / sleep_until entries.
// Sleep registers a TimerEntry into the current runtime's time wheel on
// first poll and resolves once the wheel fires the deadline.

use runtime
use io
use sys
use asyncio.runtime as rt
use asyncio.runtime.time as rttime

// Resolve the current runtime's TimeHandle, or null when running outside a
// runtime / with the time driver disabled.
fn current_time_handle() rttime.TimeHandle {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return null
    dh<rt.DriverHandle> = rc.driver.(rt.DriverHandle)
    if dh == null return null
    return dh.time_handle
}

// Absolute deadline (ms since the time source origin) for a relative delay.
// Falls back to a bare delay when no runtime clock is available.
fn deadline_from_duration(d<sys.Duration>) u64 {
    th<rttime.TimeHandle> = current_time_handle()
    now<u64> = 0
    if th != null now = th.clock.now_ms()
    return now + d.as_millis()
}

// Absolute deadline (ms since origin) for an absolute Instant. Reads the
// u64 ns fields directly to avoid passing embedded mem values by address.
fn deadline_from_instant(when<rttime.Instant>) u64 {
    th<rttime.TimeHandle> = current_time_handle()
    if th == null return 0
    when_ns<u64>   = when.ns_since_epoch
    origin_ns<u64> = th.source.origin.ns_since_epoch
    if when_ns <= origin_ns return 0
    return (when_ns - origin_ns) / 1000000
}

// Async leaf future for a single deadline. registered flips 0 -> 1 the
// first time poll links the entry into the wheel.
mem Sleep: async {
    rttime.TimerEntry* entry
    i32                registered
}

// Link into the wheel on first poll, then defer to the entry's state cell.
// Returns PollReady, io.Ok once fired; PollReady, TimerShutdown when the
// entry was deregistered (driver gone / no runtime); PollPending otherwise.
Sleep::poll(ctx){
    if this.registered == 0 {
        th<rttime.TimeHandle> = current_time_handle()
        if th != null th.register(this.entry)
        this.registered = 1
    }
    code<i32> = this.entry.poll_elapsed(ctx.(u64))
    if code == rttime.RESULT_FIRED return runtime.PollReady, io.Ok
    if code == rttime.RESULT_CANCELLED return runtime.PollReady, TimerShutdown
    return runtime.PollPending
}

// Sleep for `d`. Resolves to io.Ok once the deadline fires.
async sleep(d<sys.Duration>) i32 {
    deadline<u64> = deadline_from_duration(d)
    e<rttime.TimerEntry> = rttime.TimerEntry::new(deadline)
    s<Sleep> = new Sleep { entry: e, registered: 0 }
    return s.await
}

// Sleep until the absolute Instant `when`. Resolves to io.Ok once fired.
async sleep_until(when<rttime.Instant>) i32 {
    deadline<u64> = deadline_from_instant(when)
    e<rttime.TimerEntry> = rttime.TimerEntry::new(deadline)
    s<Sleep> = new Sleep { entry: e, registered: 0 }
    return s.await
}
