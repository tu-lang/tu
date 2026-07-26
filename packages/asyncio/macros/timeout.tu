// timeout / timeout_at: poll the value future first,
// then the Sleep delay; delay Ready yields Elapsed.
//
// Returns (err, value): err==io.Ok with value on success; err==TIMEOUT_ELAPSED
// when the delay fires first.

use runtime
use io
use sys
use asyncio.time as atime
use asyncio.runtime.time as rttime

// The design / asyncio.error.Elapsed.
TIMEOUT_ELAPSED<i32> = 0x03020004

mem Timeout: async {
    runtime.Future* value
    runtime.Future* delay
}

// Value first, then delay.
Timeout::poll(ctx){
    packed<u64> = ctx.(u64)
    ready_i<i64> = 0
    val_i<i64> = 0
    ready_i, val_i = poll_child(this.value, packed)
    if ready_i == runtime.PollReady {
        ok_code<i32> = io.Ok
        return runtime.PollReady, ok_code, val_i
    }
    if ready_i == runtime.PollError {
        return runtime.PollError, 0.(i64), 0.(i64)
    }

    d_ready<i64> = 0
    d_val<i64> = 0
    d_ready, d_val = poll_child(this.delay, packed)
    if d_ready == runtime.PollReady {
        code_e<i32> = TIMEOUT_ELAPSED
        return runtime.PollReady, code_e, 0.(i64)
    }
    if d_ready == runtime.PollError {
        return runtime.PollError, 0.(i64), 0.(i64)
    }
    return runtime.PollPending
}

fn timeout(d<sys.Duration>, fut<runtime.Future>) Timeout {
    delay_f<runtime.Future> = atime.sleep(d)
    return new Timeout { value: fut, delay: delay_f }
}

fn timeout_at(when<rttime.Instant>, fut<runtime.Future>) Timeout {
    delay_f<runtime.Future> = atime.sleep_until(when)
    return new Timeout { value: fut, delay: delay_f }
}
