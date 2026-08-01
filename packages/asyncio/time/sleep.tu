// User-facing sleep / sleep_until. Builds a runtime.time Sleep leaf (traced
// TimerEntry*) and returns it for await / join / select.

use runtime
use sys
use asyncio.runtime as rt
use asyncio.runtime.time as rttime

// Prefer context handle; fall back to handle published by builder_block_on.
fn current_time_handle() rttime.TimeHandle {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc != null {
        dh<rt.DriverHandle> = rt.context_driver_handle(rc)
        if dh != null && dh.time_handle != null {
            return dh.time_handle
        }
    }
    return rttime.sleep_active_handle()
}

fn deadline_from_duration(d<sys.Duration>) u64 {
    rel_ms<u64> = d.as_millis()
    th<rttime.TimeHandle> = current_time_handle()
    if th == null return rel_ms
    now_ms<u64> = rttime.time_handle_now_ms(th)
    return now_ms + rel_ms
}

fn deadline_from_instant(when<rttime.Instant>) u64 {
    th<rttime.TimeHandle> = current_time_handle()
    if th == null return 0
    when_ns<u64> = when.ns_since_epoch
    now_ms<u64> = rttime.time_handle_now_ms(th)
    now_ns<u64> = now_ms * 1000000
    if when_ns <= now_ns return now_ms
    return when_ns / 1000000
}

fn sleep(d<sys.Duration>) runtime.Future {
    // Refresh publish from context when available; never wipe with null.
    rttime.sleep_set_handle(current_time_handle())
    // Defer now+duration until Sleep::poll — dual() may be built before
    // block_on publishes TimeHandle (eager arg eval).
    s = rttime.sleep_new_duration(d.as_millis())
    fut<runtime.Future> = s
    return fut
}

fn sleep_until(when<rttime.Instant>) runtime.Future {
    rttime.sleep_set_handle(current_time_handle())
    deadline<u64> = deadline_from_instant(when)
    s = rttime.sleep_new(deadline)
    fut<runtime.Future> = s
    return fut
}
