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

    // The runtime root stores the Handle pointer in sched_handle for
    // first-pass simplicity; later phases may split scheduler-only ops
    // out behind a thinner interface.
    sched_bits<u64> = rc.sched
    h<Handle> = sched_bits.(Handle)
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

// Package-level block_on dispatch (avoids weak_handle.block_on parser trap).
fn handle_block_on_impl(h<Handle>, fut) i32, i64 {
    if h.sched_kind == 1 {
        return RT_RUNTIME_SHUTDOWN, 0
    }
    return scheduler.block_on_raw(h.sched_handle, fut)
}

// Shared blocking-pool spawn wiring (keeps cross-package assertions out of methods).
fn handle_blocking_impl(h<Handle>, op<u64>, mandatory<i32>) task.JoinHandle {
    sp<rtblk.Spawner> = rtblk.spawner_from_bits(h.blocking_spawner)
    if sp == null {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }

    inject<scheduler.Inject> = null
    if h.sched_kind == 1 {
        inject = scheduler.mt_sched_inject(h.sched_handle)
    } else {
        inject = scheduler.ct_sched_inject(h.sched_handle)
    }

    bsched<rtblk.BlockingSchedule> = rtblk.BlockingSchedule::new(inject)
    tid<task.TaskId> = task.alloc_id()
    jh2<task.JoinHandle> = new task.JoinHandle
    jh_bits<u64> = 0
    jh_bits = jh2
    raw<task.RawTask> = task.raw_new(jh_bits, bsched, tid.v)
    // Mother: header().state.ref_dec() after wiring JoinHandle
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

// Run fut to completion via the active scheduler's block_on.
Handle::block_on(fut) i32, i64 {
    if this.sched_kind == 1 {
        // multi_thread does not own block_on directly; route through the
        // current_thread's caller. The runtime root's block_on shim
        // handles this dispatch.
        return RT_RUNTIME_SHUTDOWN, 0
    }
    return handle_block_on_impl(this, fut)
}
