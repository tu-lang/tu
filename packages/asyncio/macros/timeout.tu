// Library-function form of tokio::time::timeout, built on select2 + sleep.
// Races `fut` against a sleep of `d`; if the sleep wins, the operation timed
// out (aerr.Elapsed), otherwise `fut`'s value is returned.
//
// Design note (§14.8): time.timeout was deferred until select2 existed; it now
// lives here and time.timeout can re-export this.

use runtime
use io
use sys
use asyncio.time as atime
use asyncio.runtime.time as rttime
use asyncio.error as aerr

// Run `fut`, cancelling it after `d`. Returns (io.Ok, value) when `fut`
// resolves first, or (aerr.Elapsed, 0) when the timer fires first.
async timeout(d<sys.Duration>, fut<runtime.Future>) i32, i64 {
    sleepfut<runtime.Future> = atime.sleep(d)
    which<i32>, val<i64> = select2(fut, sleepfut).await
    if which == SELECT_SECOND_READY return aerr.Elapsed, 0
    return io.Ok, val
}

// Absolute-deadline variant: cancel `fut` once `when` passes.
async timeout_at(when<rttime.Instant>, fut<runtime.Future>) i32, i64 {
    sleepfut<runtime.Future> = atime.sleep_until(when)
    which<i32>, val<i64> = select2(fut, sleepfut).await
    if which == SELECT_SECOND_READY return aerr.Elapsed, 0
    return io.Ok, val
}
