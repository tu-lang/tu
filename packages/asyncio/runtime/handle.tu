use io
use asyncio.task
use asyncio.runtime.scheduler
use asyncio.runtime.blocking
use asyncio.runtime.blocking as rtblk

// Cross-thread weak handle to a Runtime. spawn / spawn_blocking /
// (current_thread.CtHandle and multi_thread.MtHandle) implement
// task.Schedule but the union type stays opaque at this layer.
mem Handle {
    u64           sched_handle      // CtHandle* or MtHandle* raw bits
    i32           sched_kind        // 0 = current_thread, 1 = multi_thread
    DriverHandle* drv_h             // avoids .driver vs type Driver trap
    u64           blocking_spawner  // raw bits of blocking.Spawner*
}

// Build a fresh weak handle.
const Handle::new(sched<u64>, kind<i32>, driver<DriverHandle>, blocking<u64>) Handle {
    h<Handle> = new Handle
    h.sched_handle     = sched
    h.sched_kind       = kind
    h.drv_h            = driver
    h.blocking_spawner = blocking
    return h
}

// Look up the active Handle. Returns (OtherRuntime1XNotFound, null)
// outside any runtime context.
const Handle::current() i32, Handle {
    rc<RuntimeContext> = current_context()
    if rc == null return io.OtherRuntime1XNotFound, null

    if rc.wh_bits == 0 return io.OtherRuntime1XNotFound, null
    h<Handle> = rc.wh_bits.(Handle)
    return 0, h
}

// Package-level dispatch (Handle::spawn name confuses parser on return paths).
fn handle_spawn_impl(h<Handle>, fut) task.JoinHandle {
    if h.sched_kind == 1 {
        return scheduler.mt_handle_spawn_raw(h.sched_handle, fut)
    }
    return scheduler.ct_handle_spawn_raw(h.sched_handle, fut)
}

// Spawn a future via the active scheduler. Routes by sched_kind.
Handle::spawn(fut) task.JoinHandle {
    return handle_spawn_impl(this, fut)
}

// Run fut to completion via the active scheduler's block_on.
Handle::block_on(fut) i32, i64 {
    err<i32> = 0
    val<i64> = 0
    err, val = handle_block_on_bridge(this, fut)
    return err, val
}

// Shared blocking-pool spawn wiring (keeps cross-package assertions out of methods).
fn handle_blocking_impl(h<Handle>, op<u64>, mandatory<i32>) task.JoinHandle {
    sp<rtblk.Spawner> = rtblk.spawner_from_bits(h.blocking_spawner)
    if sp == null {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }

    // unowned(fut, BlockingSchedule::new()) — Schedule is Noop for re-poll;
    // JoinHandle wake uses the awaiter's CtHandle/MtHandle.
    bsched<rtblk.BlockingSchedule> = rtblk.BlockingSchedule::new()
    tid<task.TaskId> = task.alloc_id()
    jh2<task.JoinHandle> = new task.JoinHandle
    jh_bits<u64> = 0
    jh_bits = jh2
    bsf<u64> = 0
    brf<u64> = 0
    bsf, brf = rtblk.blocking_sched_bridge_fns()
    raw<task.RawTask> = task.raw_new(jh_bits, bsched, bsf, brf, tid.v)
    life_st<task.TaskState> = raw.life_st()
    life_st.ref_dec()
    jh2.init(raw)

    bt<rtblk.BlockingTask> = rtblk.BlockingTask::new(op, raw)
    item<rtblk.BlockingTaskItem> = rtblk.BlockingTaskItem::new(bt, mandatory)
    err<i32> = 0
    if mandatory == 1 {
        err = rtblk.spawner_submit_mandatory(sp, item)
    } else {
        err = rtblk.spawner_submit(sp, item)
    }
    if err != 0 {
        jh2.init(null)
    }
    return jh2
}

// Spawn a sync closure on the blocking pool. Returns a JoinHandle the
// caller can await for the u64 result.
Handle::spawn_blocking(op<u64>) task.JoinHandle {
    return handle_blocking_impl(this, op, 0)
}

// Spawn a mandatory blocking closure (DNS / fs flush paths).
Handle::spawn_mandatory_blocking(op<u64>) task.JoinHandle {
    return handle_blocking_impl(this, op, 1)
}
