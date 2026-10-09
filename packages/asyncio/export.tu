// Dynamic facade of the root package: block on / spawn for dyn callers.
// `use asyncio` then asyncio.blockOnCt / blockOnMt / go; dyn inputs and outputs.

use asyncio.runtime as rt
use asyncio.task
use asyncio.util

// Builds a runtime (kind 1 = multi_thread, else current_thread) and blocks on
// the future bits. Returns (runtime err, async body result).
fn dyn_block_on(kind<i32>, workers<u32>, io_on<i32>, time_on<i32>, fut_bits<u64>) (i32, i64) {
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
export func blockOnCt(fut) {
    bits<u64> = fut.(u64)
    err<i32>, val<i64> = dyn_block_on(0, 1.(u32), 1, 1, bits)
    if err != 0 {
        out = err
        return out
    }
    out = val
    return out
}

// Block on fut with multi_thread(workers) + enable_all.
// Returns a dynamic int: runtime err, or the async body result.
export func blockOnMt(workers, fut) {
    w_i<i32> = util.dyn_i32(workers)
    if w_i <= 0 {
        w_i = 1
    }
    w<u32> = w_i.(u32)
    bits<u64> = fut.(u64)
    err<i32>, val<i64> = dyn_block_on(1, w, 1, 1, bits)
    if err != 0 {
        out = err
        return out
    }
    out = val
    return out
}

// Spawn fut on the current runtime and detach it (fire and forget).
// Tu has no Drop: an undetached JoinHandle leaks task refs and wedges
// long-lived servers. Returns 0, or the runtime err outside a runtime.
export func go(fut) {
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err
    }
    jh<task.JoinHandle> = h.spawn(fut)
    jh.detach()
    return 0
}
