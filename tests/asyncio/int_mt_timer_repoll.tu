// MT enable_all timer park must survive eventfd early wake + re-poll.
// Repro gate: consecutive Sleep / insert-wake / select short arm / abort.
// Do not "fix" by absorbing wakeups inside park — mother is one turn then
// re-poll; that path must be SEGV-free under multi_thread block_on.

use fmt
use os
use io
use asyncio.runtime as rt
use asyncio.time as atime
use asyncio.macros as m
use asyncio.task

fn check(ok<i32>, msg) {
    if ok != 0 return
    fmt.println(msg)
    os.exit(1)
}

// Many short sleeps: each register insert-wakes the reactor; park often
// returns before the deadline and block_on must re-poll safely.
async consec_sleep_body() {
    round<i32> = 0
    while round < 12 {
        e0<i32> = atime.sleep(atime.from_millis(5)).await
        if e0 != io.Ok return e0.(i64)
        round += 1
    }
    return io.Ok.(i64)
}

fn run_consec(label, workers<u32>) {
    fmt.println(label)
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(workers)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, consec_sleep_body(), 0)
    check(err == 0, "consec block_on failed")
    check(val.(i32) == io.Ok, "consec body failed")
    fmt.println(label)
    fmt.println("passed")
}

// Longer sleeps still use blocking epoll(eff); must not SEGV either.
async long_sleep_body() {
    round<i32> = 0
    while round < 4 {
        e0<i32> = atime.sleep(atime.from_millis(40)).await
        if e0 != io.Ok return e0.(i64)
        round += 1
    }
    return io.Ok.(i64)
}

fn run_long() {
    fmt.println("int_mt_timer_repoll_long")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, long_sleep_body(), 0)
    check(err == 0, "long block_on failed")
    check(val.(i32) == io.Ok, "long body failed")
    fmt.println("int_mt_timer_repoll_long passed")
}

// Empty-wheel park must not sleep the full limit or both select arms Ready.
async select_short_body() {
    w<i32> = m.select2(
        atime.sleep(atime.from_millis(5)),
        atime.sleep(atime.from_millis(50))
    ).await
    first<i32> = 1
    if w != first {
        return io.OtherParse.(i64)
    }
    return io.Ok.(i64)
}

fn run_select_short() {
    fmt.println("int_mt_timer_repoll_select_short")
    n<i32> = 0
    while n < 30 {
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        err<i32>, val<i64> = rt.builder_block_on(b, select_short_body(), 0)
        check(err == 0, "select_short block_on failed")
        check(val.(i32) == io.Ok, "select_short long arm won")
        n += 1
    }
    fmt.println("int_mt_timer_repoll_select_short passed")
}

// Abort a long Sleep while the reactor may be in timed epoll (cancel path).
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

fn run_abort_cycles() {
    fmt.println("int_mt_timer_repoll_abort")
    n<i32> = 0
    while n < 12 {
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        err<i32>, val<i64> = rt.builder_block_on(b, abort_sleep_body(), 0)
        check(err == 0, "abort block_on failed")
        check(val.(i32) == io.Ok, "abort body failed")
        n += 1
    }
    fmt.println("int_mt_timer_repoll_abort passed")
}

fn main() {
    run_consec("int_mt_timer_repoll_w1", 1)
    run_consec("int_mt_timer_repoll_w4", 4)
    run_long()
    run_select_short()
    run_abort_cycles()
}
