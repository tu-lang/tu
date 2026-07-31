// Integration test: spawn_blocking returns u64 through JoinHandle (task 8.12).

use fmt
use os
use io
use asyncio.runtime as rt
use asyncio.task

fn blocking_return_42() u64 {
    return 42.(u64)
}

async blocking_pool_body() {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err.(i64)
    }
    op_bits<u64> = blocking_return_42.(u64)
    jh<task.JoinHandle> = h.spawn_blocking(op_bits)
    val<i64> = jh.await
    if val != 42 {
        bad<i32> = io.OtherParse
        return bad.(i64)
    }
    ok<i32> = io.Ok
    return ok.(i64)
}

fn int_blocking_pool_basic() {
    fmt.println("int_blocking_pool_basic")
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, blocking_pool_body(), 0)
    if rerr != 0 {
        os.dief("block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("blocking body failed: %d", ri)
    }
    fmt.println("int_blocking_pool_basic passed")
}

// Same spawn_blocking path under multi_thread + enable_all (workers + pool).
fn int_blocking_pool_mt() {
    fmt.println("int_blocking_pool_mt")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, blocking_pool_body(), 0)
    if rerr != 0 {
        os.dief("mt block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("mt blocking body failed: %d", ri)
    }
    fmt.println("int_blocking_pool_mt passed")
}

// Several MT runtimes in one process after blocking work (shutdown stress).
fn int_blocking_pool_mt_cycles() {
    fmt.println("int_blocking_pool_mt_cycles")
    n<i32> = 0
    while n < 6 {
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        rerr<i32>, result<i64> = rt.builder_block_on(b, blocking_pool_body(), 0)
        if rerr != 0 {
            os.dief("cycle block_on failed: %d", rerr)
        }
        ri<i32> = result
        if ri != io.Ok {
            os.dief("cycle body failed: %d", ri)
        }
        n += 1
    }
    fmt.println("int_blocking_pool_mt_cycles passed")
}

fn main() {
    int_blocking_pool_basic()
    int_blocking_pool_mt()
    int_blocking_pool_mt_cycles()
}
