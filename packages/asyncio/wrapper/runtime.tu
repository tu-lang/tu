// Runtime blockOn / spawn entry for asyncio.wrapper (camelCase public API).
// Public surface is func; engine Builder stays internal.

use asyncio.runtime as rt
use asyncio.task as task

fn runtime_block_on(kind<i32>, workers<u32>, io_on<i32>, time_on<i32>, fut_bits<u64>) (i32, i64) {
    b<rt.Builder> = null
    if kind == 1 {
        b = rt.Builder::new_multi_thread()
    } else {
        b = rt.Builder::new_current_thread()
    }
    b = b.worker_threads(workers)
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

// Block on fut with current_thread + enable_all.
// Returns a dynamic int: runtime err, or the async body result.
func blockOnCt(fut) {
    bits<u64> = fut.(u64)
    err<i32>, val<i64> = runtime_block_on(0, 1.(u32), 1, 1, bits)
    if err != 0 {
        out = err
        return out
    }
    out = val
    return out
}

// Block on fut with multi_thread(workers) + enable_all.
// Returns a dynamic int: runtime err, or the async body result.
func blockOnMt(workers, fut) {
    w_i<i32> = dyn_i32(workers)
    if w_i <= 0 {
        w_i = 1
    }
    w<u32> = w_i.(u32)
    bits<u64> = fut.(u64)
    err<i32>, val<i64> = runtime_block_on(1, w, 1, 1, bits)
    if err != 0 {
        out = err
        return out
    }
    out = val
    return out
}

// Schedule fut on the current runtime Handle.
// Detach the JoinHandle immediately — Tu has no Drop; discarding the handle
// without detach leaks task refs and wedges long-lived servers (ab n=50k).
func spawn(fut) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err
    }
    jh<task.JoinHandle> = h.spawn(fut)
    jh.detach()
    return 0
}
