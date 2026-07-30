// Integration test for multi_thread block_on (task 9.41).
// 4 workers; Handle::current; nested spawn / wake use schedule_local.
// Fan-out stresses wake-local LIFO + steal across workers.

use fmt
use os
use runtime
use asyncio.task
use asyncio.runtime as rt

mem CurrentOkFut: async {
    i64 _pad
}
CurrentOkFut::poll(ctx) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return runtime.PollReady, 0.(i64)
    }
    if h == null {
        return runtime.PollReady, 0.(i64)
    }
    return runtime.PollReady, 1.(i64)
}

fn current_ok_fut() runtime.Future {
    f<CurrentOkFut> = new CurrentOkFut{}
    fut<runtime.Future> = f
    return fut
}

async mt_spawn_join_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh1<task.JoinHandle> = h.spawn(current_ok_fut())
    jh2<task.JoinHandle> = h.spawn(current_ok_fut())
    v1<i64> = jh1.await
    v2<i64> = jh2.await
    sum<i32> = v1.(i32) + v2.(i32)
    return sum.(i64)
}

// Nested spawn: worker polls outer, spawn goes schedule_local LIFO.
async mt_nested_inner() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return 0.(i64)
    jh<task.JoinHandle> = h.spawn(current_ok_fut())
    v<i64> = jh.await
    return v
}

fn nested_inner_fut() runtime.Future {
    return mt_nested_inner()
}

async mt_nested_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh<task.JoinHandle> = h.spawn(nested_inner_fut())
    v<i64> = jh.await
    return v
}

// Burst spawn then join: children race across workers (steal); each join
// completion wakes via Schedule → wake-side schedule_local.
async mt_fanout_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    sum<i64> = 0
    wave<i32> = 0
    while wave < 4 {
        j0<task.JoinHandle> = h.spawn(current_ok_fut())
        j1<task.JoinHandle> = h.spawn(current_ok_fut())
        j2<task.JoinHandle> = h.spawn(current_ok_fut())
        j3<task.JoinHandle> = h.spawn(current_ok_fut())
        j4<task.JoinHandle> = h.spawn(current_ok_fut())
        j5<task.JoinHandle> = h.spawn(current_ok_fut())
        j6<task.JoinHandle> = h.spawn(current_ok_fut())
        j7<task.JoinHandle> = h.spawn(current_ok_fut())
        sum = sum + j0.await
        sum = sum + j1.await
        sum = sum + j2.await
        sum = sum + j3.await
        sum = sum + j4.await
        sum = sum + j5.await
        sum = sum + j6.await
        sum = sum + j7.await
        wave += 1
    }
    return sum
}

fn int_multi_thread(){
    fmt.println("int_multi_thread test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    err<i32>, val<i64> = rt.builder_block_on(b, mt_spawn_join_body(), 0)
    if err != 0 os.dief("block_on failed: %d", err)
    sum<i32> = val.(i32)
    if sum != 2 os.dief("expected count 2, got %d", sum)
    fmt.println("int_multi_thread passed")
}

fn int_multi_thread_nested(){
    fmt.println("int_multi_thread_nested test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    err<i32>, val<i64> = rt.builder_block_on(b, mt_nested_body(), 0)
    if err != 0 os.dief("nested block_on failed: %d", err)
    if val.(i32) != 1 os.dief("expected nested 1, got %d", val.(i32))
    fmt.println("int_multi_thread_nested passed")
}

fn int_multi_thread_fanout(){
    fmt.println("int_multi_thread_fanout test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    err<i32>, val<i64> = rt.builder_block_on(b, mt_fanout_body(), 0)
    if err != 0 os.dief("fanout block_on failed: %d", err)
    if val.(i32) != 32 os.dief("expected fanout sum 32, got %d", val.(i32))
    fmt.println("int_multi_thread_fanout passed")
}

fn main(){
    int_multi_thread()
    int_multi_thread_nested()
    int_multi_thread_fanout()
}
