// Integration test for multi_thread block_on (task 9.41).
// 4 workers; Handle::current on worker tasks; sum=2.
// Nested/batch/local-LIFO deferred (schedule_local flaky — optimize debt).

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

fn main(){
    int_multi_thread()
}
