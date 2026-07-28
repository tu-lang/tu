// Integration test for multi_thread block_on (task 9.41).
// Builds a 4-worker runtime, block_on an async body that spawns two
// ready futures via Handle::current, awaits both, and checks sum=2.
// Scale-out to 100 sequential spawns blocked by MT async-for codegen
// (see co/docs/optimize/2026-07-28-mt-block-on-production.md).

use fmt
use os
use runtime
use asyncio.task
use asyncio.runtime as rt

mem UnitFut: async {
    i64 val
}
UnitFut::poll(ctx) {
    return runtime.PollReady, this.val
}

fn unit_fut() runtime.Future {
    f<UnitFut> = new UnitFut{}
    f.val = 1
    fut<runtime.Future> = f
    return fut
}

async mt_spawn_join_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 return err.(i64)
    jh1<task.JoinHandle> = h.spawn(unit_fut())
    jh2<task.JoinHandle> = h.spawn(unit_fut())
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
