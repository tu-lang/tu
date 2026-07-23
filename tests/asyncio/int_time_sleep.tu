// Integration test: asyncio coroutine Sleep (TimeDriver park wake).
// Awaits a concrete runtime.time.Sleep leaf on current_thread + enable_time.
// Mother: tokio::time::sleep — Pending until the wheel fires the deadline.
//
// Await the Sleep mem directly (runtime.Future cannot .await). Same pattern
// as asyncio.time.Interval::tick.

use fmt
use os
use io
use std
use runtime
use asyncio.runtime as rt
use asyncio.runtime.time as rttime
use asyncio.time as atime

fn mono_ns() i64 {
    ts<std.TimeSpec:> = null
    std.clock_gettime(std.CLOCK_MONOTONIC, ts)
    return ts.sec * 1000000000 + ts.nsec
}

// One ~50ms Sleep via public atime.sleep + await as Sleep leaf.
async sleep_once_body() {
    hold_ms<u64> = 50
    fut<runtime.Future> = atime.sleep(atime.from_millis(hold_ms))
    delay_f<rttime.Sleep> = fut
    before<i64> = mono_ns()
    delay_err<i32> = delay_f.await
    after<i64> = mono_ns()
    fmt.println("sleep_err")
    fmt.println(int(delay_err))
    if delay_err != io.Ok return delay_err

    elapsed_ns<i64> = after - before
    min_ns<i64> = 30000000
    fmt.println("elapsed_ms")
    fmt.println(int(elapsed_ns / 1000000))
    if elapsed_ns < min_ns {
        fmt.println("sleep too short")
        return io.OtherParse
    }
    return io.Ok
}

// Two consecutive sleeps (re-register on the wheel).
async sleep_twice_body() {
    fut1<runtime.Future> = atime.sleep(atime.from_millis(20))
    d1<rttime.Sleep> = fut1
    e1<i32> = d1.await
    if e1 != io.Ok return e1

    fut2<runtime.Future> = atime.sleep(atime.from_millis(20))
    d2<rttime.Sleep> = fut2
    e2<i32> = d2.await
    if e2 != io.Ok return e2
    return io.Ok
}

fn run_sleep_once() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_time()
    body_f<runtime.Future> = sleep_once_body()
    fut_bits<u64> = 0
    fut_bits = body_f
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut_bits, 0)
    if rerr != 0 {
        fmt.println("block_on failed")
        fmt.println(int(rerr))
        os.exit(1)
    }
    ri<i32> = 0
    ri = result
    if ri != io.Ok {
        fmt.println("sleep_once body failed")
        fmt.println(int(ri))
        os.exit(1)
    }
    fmt.println("  sleep_once passed")
}

fn run_sleep_twice() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_time()
    body_f<runtime.Future> = sleep_twice_body()
    fut_bits<u64> = 0
    fut_bits = body_f
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut_bits, 0)
    if rerr != 0 {
        fmt.println("block_on failed")
        fmt.println(int(rerr))
        os.exit(1)
    }
    ri<i32> = 0
    ri = result
    if ri != io.Ok {
        fmt.println("sleep_twice body failed")
        fmt.println(int(ri))
        os.exit(1)
    }
    fmt.println("  sleep_twice passed")
}

fn int_time_sleep() {
    fmt.println("int_time_sleep test")
    run_sleep_once()
    run_sleep_twice()
    fmt.println("int_time_sleep passed")
}

fn main() {
    int_time_sleep()
}
