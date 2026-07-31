// Integration: macros.timeout elapsed/ok + JoinHandle.abort cancellation.
// Covers tasks 19.8 / 3.29 user paths under multi_thread + enable_all.

use fmt
use os
use io
use runtime
use string
use asyncio.runtime as rt
use asyncio.task
use asyncio.macros as m
use asyncio.time as atime

// timeout(20ms, sleep 100ms) → TIMEOUT_ELAPSED (asyncio.macros).
TIMEOUT_ELAPSED<i32> = 0x03020004

async timeout_elapsed_body() {
    code<i32> = m.timeout(
        atime.from_millis(20),
        atime.sleep(atime.from_millis(100))
    ).await
    if code != TIMEOUT_ELAPSED return io.OtherParse.(i64)
    return io.Ok.(i64)
}

async timeout_ok_body() {
    code<i32> = m.timeout(
        atime.from_millis(200),
        atime.sleep(atime.from_millis(10))
    ).await
    if code != io.Ok return io.OtherParse.(i64)
    return io.Ok.(i64)
}

mem LongSleepFut: async {
    i64 _pad
}
LongSleepFut::poll(ctx) {
    // Never ready — abort must cancel before completion.
    return runtime.PollPending
}

fn long_sleep_fut() runtime.Future {
    f<LongSleepFut> = new LongSleepFut{}
    fut<runtime.Future> = f
    return fut
}

async abort_pending_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(long_sleep_fut())
    jh.abort()
    v<i64> = jh.await
    if v.(i32) != task.JoinErrorCancelled {
        return io.OtherParse.(i64)
    }
    return io.Ok.(i64)
}

async abort_sleep_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(atime.sleep(atime.from_millis(5000)))
    e1<i32> = atime.sleep(atime.from_millis(10)).await
    if e1 != io.Ok return e1.(i64)
    jh.abort()
    v<i64> = jh.await
    if v.(i32) != task.JoinErrorCancelled {
        return io.OtherParse.(i64)
    }
    return io.Ok.(i64)
}

fn run_mt(name, body) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 os.dief("%s block_on failed: %d", name, rerr)
    ri<i32> = result
    if ri != io.Ok os.dief("%s body failed: %d", name, ri)
    fmt.println(name)
}

fn int_timeout_cancel() {
    fmt.println("int_timeout_cancel test")
    run_mt("  timeout_elapsed passed", timeout_elapsed_body())
    run_mt("  timeout_ok passed", timeout_ok_body())
    run_mt("  abort_pending passed", abort_pending_body())
    run_mt("  abort_sleep passed", abort_sleep_body())
    fmt.println("int_timeout_cancel passed")
}

fn main() {
    int_timeout_cancel()
}
