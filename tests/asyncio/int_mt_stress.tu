// MT scheduler stress / race coverage. Not a smoke test.
// Waves of spawn+join, nested depth, short/long sleep park, sleep+spawn mix,
// abort under load, and many same-process multi_thread block_on cycles.

use fmt
use os
use io
use runtime
use asyncio.task
use asyncio.runtime as rt
use asyncio.time as atime
use asyncio.macros as m

fn check(ok<i32>, msg) {
    if ok != 0 return
    fmt.println(msg)
    os.exit(1)
}

mem UnitOkFut: async {
    i64 _pad
}
UnitOkFut::poll(ctx) {
    return runtime.PollReady, 1.(i64)
}

fn unit_ok_fut() runtime.Future {
    f<UnitOkFut> = new UnitOkFut{}
    fut<runtime.Future> = f
    return fut
}

mem PendForeverFut: async {
    i64 _pad
}
PendForeverFut::poll(ctx) {
    return runtime.PollPending
}

fn pend_forever_fut() runtime.Future {
    f<PendForeverFut> = new PendForeverFut{}
    fut<runtime.Future> = f
    return fut
}

// ---- wave spawn: 16×16 = 256 joins across workers ----

async mt_stress_wave_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    sum<i64> = 0
    wave<i32> = 0
    while wave < 16 {
        j0<task.JoinHandle> = h.spawn(unit_ok_fut())
        j1<task.JoinHandle> = h.spawn(unit_ok_fut())
        j2<task.JoinHandle> = h.spawn(unit_ok_fut())
        j3<task.JoinHandle> = h.spawn(unit_ok_fut())
        j4<task.JoinHandle> = h.spawn(unit_ok_fut())
        j5<task.JoinHandle> = h.spawn(unit_ok_fut())
        j6<task.JoinHandle> = h.spawn(unit_ok_fut())
        j7<task.JoinHandle> = h.spawn(unit_ok_fut())
        j8<task.JoinHandle> = h.spawn(unit_ok_fut())
        j9<task.JoinHandle> = h.spawn(unit_ok_fut())
        j10<task.JoinHandle> = h.spawn(unit_ok_fut())
        j11<task.JoinHandle> = h.spawn(unit_ok_fut())
        j12<task.JoinHandle> = h.spawn(unit_ok_fut())
        j13<task.JoinHandle> = h.spawn(unit_ok_fut())
        j14<task.JoinHandle> = h.spawn(unit_ok_fut())
        j15<task.JoinHandle> = h.spawn(unit_ok_fut())
        sum = sum + j0.await
        sum = sum + j1.await
        sum = sum + j2.await
        sum = sum + j3.await
        sum = sum + j4.await
        sum = sum + j5.await
        sum = sum + j6.await
        sum = sum + j7.await
        sum = sum + j8.await
        sum = sum + j9.await
        sum = sum + j10.await
        sum = sum + j11.await
        sum = sum + j12.await
        sum = sum + j13.await
        sum = sum + j14.await
        sum = sum + j15.await
        wave += 1
    }
    return sum
}

fn int_mt_stress_wave() {
    fmt.println("int_mt_stress_wave test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_wave_body(), 0)
    check(err == 0, "wave block_on failed")
    check(val.(i32) == 256, "wave sum != 256")
    fmt.println("int_mt_stress_wave passed")
}

// ---- nested spawn depth 6 (schedule_local chain) ----

async nest_leaf() {
    return 1.(i64)
}

fn nest_leaf_fut() runtime.Future {
    return nest_leaf()
}

async nest_l1() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(nest_leaf_fut())
    return jh.await
}

fn nest_l1_fut() runtime.Future {
    return nest_l1()
}

async nest_l2() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(nest_l1_fut())
    return jh.await
}

fn nest_l2_fut() runtime.Future {
    return nest_l2()
}

async nest_l3() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(nest_l2_fut())
    return jh.await
}

fn nest_l3_fut() runtime.Future {
    return nest_l3()
}

async nest_l4() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(nest_l3_fut())
    return jh.await
}

fn nest_l4_fut() runtime.Future {
    return nest_l4()
}

async nest_l5() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(nest_l4_fut())
    return jh.await
}

fn nest_l5_fut() runtime.Future {
    return nest_l5()
}

async mt_stress_nest_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(nest_l5_fut())
    return jh.await
}

fn int_mt_stress_nest() {
    fmt.println("int_mt_stress_nest test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_nest_body(), 0)
    check(err == 0, "nest block_on failed")
    check(val.(i32) == 1, "nest depth result != 1")
    fmt.println("int_mt_stress_nest passed")
}

// ---- sleep interleaved with spawn bursts (timer park + schedule) ----

async mt_stress_sleep_mix_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    sum<i64> = 0
    round<i32> = 0
    while round < 8 {
        e0<i32> = atime.sleep(atime.from_millis(5)).await
        if e0 != io.Ok return e0.(i64)
        a0<task.JoinHandle> = h.spawn(unit_ok_fut())
        a1<task.JoinHandle> = h.spawn(unit_ok_fut())
        a2<task.JoinHandle> = h.spawn(unit_ok_fut())
        a3<task.JoinHandle> = h.spawn(unit_ok_fut())
        sum = sum + a0.await
        sum = sum + a1.await
        e1<i32> = atime.sleep(atime.from_millis(5)).await
        if e1 != io.Ok return e1.(i64)
        sum = sum + a2.await
        sum = sum + a3.await
        round += 1
    }
    return sum
}

fn int_mt_stress_sleep_mix() {
    fmt.println("int_mt_stress_sleep_mix test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_sleep_mix_body(), 0)
    check(err == 0, "sleep_mix block_on failed")
    check(val.(i32) == 32, "sleep_mix sum != 32")
    fmt.println("int_mt_stress_sleep_mix passed")
}

// ---- abort storm: spawn many pending, abort all, join cancelled ----

async mt_stress_abort_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    j0<task.JoinHandle> = h.spawn(pend_forever_fut())
    j1<task.JoinHandle> = h.spawn(pend_forever_fut())
    j2<task.JoinHandle> = h.spawn(pend_forever_fut())
    j3<task.JoinHandle> = h.spawn(pend_forever_fut())
    j4<task.JoinHandle> = h.spawn(pend_forever_fut())
    j5<task.JoinHandle> = h.spawn(pend_forever_fut())
    j6<task.JoinHandle> = h.spawn(pend_forever_fut())
    j7<task.JoinHandle> = h.spawn(pend_forever_fut())
    j0.abort()
    j1.abort()
    j2.abort()
    j3.abort()
    j4.abort()
    j5.abort()
    j6.abort()
    j7.abort()
    v0<i64> = j0.await
    v1<i64> = j1.await
    v2<i64> = j2.await
    v3<i64> = j3.await
    v4<i64> = j4.await
    v5<i64> = j5.await
    v6<i64> = j6.await
    v7<i64> = j7.await
    if v0.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v1.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v2.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v3.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v4.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v5.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v6.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    if v7.(i32) != task.JoinErrorCancelled return io.OtherParse.(i64)
    return io.Ok.(i64)
}

fn int_mt_stress_abort() {
    fmt.println("int_mt_stress_abort test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_abort_body(), 0)
    check(err == 0, "abort block_on failed")
    check(val.(i32) == io.Ok, "abort body failed")
    fmt.println("int_mt_stress_abort passed")
}

// ---- many same-process MT runtimes: create/run/shutdown cycles ----

async mt_stress_cycle_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(unit_ok_fut())
    v<i64> = jh.await
    e1<i32> = atime.sleep(atime.from_millis(2)).await
    if e1 != io.Ok return e1.(i64)
    return v
}

fn int_mt_stress_cycles() {
    fmt.println("int_mt_stress_cycles test")
    n<i32> = 0
    while n < 8 {
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_cycle_body(), 0)
        if err != 0 {
            fmt.println("cycle block_on failed")
            os.exit(1)
        }
        if val.(i32) != 1 {
            fmt.println("cycle body result != 1")
            os.exit(1)
        }
        n += 1
    }
    fmt.println("int_mt_stress_cycles passed")
}

// ---- parallel sleepers then join (driver wake fan-in) ----

async sleeper_body() {
    e1<i32> = atime.sleep(atime.from_millis(15)).await
    if e1 != io.Ok return e1.(i64)
    return 1.(i64)
}

fn sleeper_fut() runtime.Future {
    return sleeper_body()
}

async mt_stress_parallel_sleep_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    j0<task.JoinHandle> = h.spawn(sleeper_fut())
    j1<task.JoinHandle> = h.spawn(sleeper_fut())
    j2<task.JoinHandle> = h.spawn(sleeper_fut())
    j3<task.JoinHandle> = h.spawn(sleeper_fut())
    j4<task.JoinHandle> = h.spawn(sleeper_fut())
    j5<task.JoinHandle> = h.spawn(sleeper_fut())
    j6<task.JoinHandle> = h.spawn(sleeper_fut())
    j7<task.JoinHandle> = h.spawn(sleeper_fut())
    sum<i64> = 0
    sum = sum + j0.await
    sum = sum + j1.await
    sum = sum + j2.await
    sum = sum + j3.await
    sum = sum + j4.await
    sum = sum + j5.await
    sum = sum + j6.await
    sum = sum + j7.await
    return sum
}

fn int_mt_stress_parallel_sleep() {
    fmt.println("int_mt_stress_parallel_sleep test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_parallel_sleep_body(), 0)
    check(err == 0, "parallel_sleep block_on failed")
    check(val.(i32) == 8, "parallel_sleep sum != 8")
    fmt.println("int_mt_stress_parallel_sleep passed")
}

// ---- many consecutive sleeps (MT enable_all timer park) ----

async mt_stress_multi_sleep_body() {
    round<i32> = 0
    while round < 8 {
        e0<i32> = atime.sleep(atime.from_millis(5)).await
        if e0 != io.Ok return e0.(i64)
        round += 1
    }
    return io.Ok.(i64)
}

fn int_mt_stress_multi_sleep() {
    fmt.println("int_mt_stress_multi_sleep test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_multi_sleep_body(), 0)
    check(err == 0, "multi_sleep block_on failed")
    check(val.(i32) == io.Ok, "multi_sleep body failed")
    fmt.println("int_mt_stress_multi_sleep passed")
}

// ---- longer sleeps (chunked park wait; short 5ms alone missed ≥35ms SEGV) ----

async mt_stress_long_sleep_body() {
    round<i32> = 0
    while round < 4 {
        e0<i32> = atime.sleep(atime.from_millis(50)).await
        if e0 != io.Ok return e0.(i64)
        round += 1
    }
    return io.Ok.(i64)
}

fn int_mt_stress_long_sleep() {
    fmt.println("int_mt_stress_long_sleep test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_long_sleep_body(), 0)
    check(err == 0, "long_sleep block_on failed")
    check(val.(i32) == io.Ok, "long_sleep body failed")
    // Time-only MT: park_before/after without IO turn.
    b2<rt.Builder> = rt.Builder::new_multi_thread()
    b2 = b2.worker_threads(4)
    b2 = b2.enable_time()
    err2<i32>, val2<i64> = rt.builder_block_on(b2, mt_stress_long_sleep_body(), 0)
    check(err2 == 0, "long_sleep time-only block_on failed")
    check(val2.(i32) == io.Ok, "long_sleep time-only body failed")
    fmt.println("int_mt_stress_long_sleep passed")
}

// ---- select short arm must win across many fresh MT runtimes ----

async mt_stress_select_short_body() {
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

fn int_mt_stress_select_short() {
    fmt.println("int_mt_stress_select_short test")
    n<i32> = 0
    while n < 20 {
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_select_short_body(), 0)
        check(err == 0, "select_short block_on failed")
        check(val.(i32) == io.Ok, "select_short long arm won")
        n += 1
    }
    fmt.println("int_mt_stress_select_short passed")
}

fn main() {
    int_mt_stress_wave()
    int_mt_stress_nest()
    int_mt_stress_multi_sleep()
    int_mt_stress_long_sleep()
    int_mt_stress_select_short()
    int_mt_stress_sleep_mix()
    int_mt_stress_abort()
    int_mt_stress_cycles()
    int_mt_stress_parallel_sleep()
}
