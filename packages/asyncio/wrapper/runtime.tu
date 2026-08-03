// Runtime blockOn / spawn entry for asyncio.wrapper (camelCase public API).

use asyncio.runtime as rt
use asyncio.task as task

fn runtime_block_on(kind<i32>, workers<u32>, io_on<i32>, time_on<i32>, fut_bits<u64>) (i32, i64) {
    b<rt.Builder> = null
    if kind == 1 {
        b = rt.Builder::new_multi_thread()
        b = b.worker_threads(workers)
    } else {
        b = rt.Builder::new_current_thread()
    }
    if io_on == 1 && time_on == 1 {
        b = b.enable_all()
    } else {
        if io_on == 1 {
            b = b.enable_io()
        }
        if time_on == 1 {
            b = b.enable_time()
        }
    }
    err<i32>, val<i64> = rt.builder_block_on(b, fut_bits, 0)
    return err, val
}

fn blockOnCt(fut) (i32, i64) {
    bits<u64> = fut.(u64)
    return runtime_block_on(0, 1.(u32), 1, 1, bits)
}

fn blockOnMt(workers, fut) (i32, i64) {
    w<u32> = workers
    bits<u64> = fut.(u64)
    return runtime_block_on(1, w, 1, 1, bits)
}

// Schedule fut on the current runtime Handle (multi_thread workers / blockOn root).
func spawn(fut) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err
    }
    h.spawn(fut)
    return 0
}
