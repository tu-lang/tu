// Integration test: asyncio coroutine Sleep (TimeDriver park wake).
// Includes multi_thread + enable_time to exercise PARKED_DRIVER.

use fmt
use os
use io
use std
use asyncio.runtime as rt
use asyncio.time as atime

fn mono_ns() i64 {
    ts<std.TimeSpec:> = null
    std.clock_gettime(std.CLOCK_MONOTONIC, ts)
    return ts.sec * 1000000000 + ts.nsec
}

async sleep_once_body() {
    hold_ms<u64> = 50
    before<i64> = mono_ns()
    delay_err<i32> = atime.sleep(atime.from_millis(hold_ms)).await
    after<i64> = mono_ns()
    if delay_err != io.Ok return delay_err

    elapsed_ns<i64> = after - before
    min_ns<i64> = 30000000
    if elapsed_ns < min_ns {
        return io.OtherParse
    }
    return io.Ok
}

async sleep_twice_body() {
    e1<i32> = atime.sleep(atime.from_millis(20)).await
    if e1 != io.Ok return e1

    e2<i32> = atime.sleep(atime.from_millis(20)).await
    if e2 != io.Ok return e2
    return io.Ok
}

fn run_sleep_once() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_time()
    rerr<i32>, result<i64> = rt.builder_block_on(b, sleep_once_body(), 0)
    if rerr != 0 {
        os.dief("sleep_once block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("sleep_once body failed: %d", ri)
    }
}

fn run_sleep_twice() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_time()
    rerr<i32>, result<i64> = rt.builder_block_on(b, sleep_twice_body(), 0)
    if rerr != 0 {
        os.dief("sleep_twice block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("sleep_twice body failed: %d", ri)
    }
}

fn run_sleep_mt() {
    fmt.println("sleep_mt test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_time()
    rerr<i32>, result<i64> = rt.builder_block_on(b, sleep_once_body(), 0)
    if rerr != 0 {
        os.dief("sleep_mt block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("sleep_mt body failed: %d", ri)
    }
    fmt.println("sleep_mt passed")
}

fn run_sleep_mt_all() {
    fmt.println("sleep_mt_all test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, sleep_once_body(), 0)
    if rerr != 0 {
        os.dief("sleep_mt_all block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("sleep_mt_all body failed: %d", ri)
    }
    fmt.println("sleep_mt_all passed")
}

fn int_time_sleep() {
    run_sleep_once()
    run_sleep_twice()
    run_sleep_mt()
    run_sleep_mt_all()
    fmt.println("int_time_sleep passed")
}

fn main() {
    int_time_sleep()
}
