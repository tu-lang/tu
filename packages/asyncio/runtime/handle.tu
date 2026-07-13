use io
use asyncio.task
use asyncio.runtime.scheduler as sched
use asyncio.runtime.blocking as rtblk

// Cross-thread weak handle to a Runtime. spawn / spawn_blocking /
// (current_thread.CtHandle and multi_thread.MtHandle) implement
// task.Schedule but the union type stays opaque at this layer.
mem Handle {
    u64           sched_handle      // CtHandle* or MtHandle* raw bits
    i32           sched_kind        // 0 = current_thread, 1 = multi_thread
    DriverHandle* driver
    u64           blocking_spawner  // raw bits of blocking.Spawner*
}

// Build a fresh weak handle.
const Handle::new(sched<u64>, kind<i32>, driver<DriverHandle>, blocking<u64>) Handle {
    h<Handle> = new Handle
    h.sched_handle     = sched
    h.sched_kind       = kind
    h.driver           = driver
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

// Spawn a future via the active scheduler. Routes by sched_kind.
Handle::spawn(fut) task.JoinHandle {
    if this.sched_kind == 1 {
        mh<sched.MtHandle> = this.sched_handle.(sched.MtHandle)
        return mh.spawn(fut)
    }
    ct<sched.CtHandle> = this.sched_handle.(sched.CtHandle)
    return ct.spawn(fut)
}

// Spawn a sync closure on the blocking pool. Returns a JoinHandle the
// caller can await for the u64 result.
Handle::spawn_blocking(op<u64>) task.JoinHandle {
    sp<rtblk.Spawner> = this.blocking_spawner.(rtblk.Spawner)
    if sp == null {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }

    inject<sched.Inject> = null
    if this.sched_kind == 1 {
        mh<sched.MtHandle> = this.sched_handle.(sched.MtHandle)
        inject = mh.shared.inject
    } else {
        ct<sched.CtHandle> = this.sched_handle.(sched.CtHandle)
        inject = ct.shared.inject
    }

    bsched<rtblk.BlockingSchedule> = rtblk.BlockingSchedule::new(inject)
    tid<task.TaskId> = task.alloc_id()
    jh<task.JoinHandle> = new task.JoinHandle
    raw<task.RawTask> = task.raw_new(jh, bsched, tid.v)
    hdr<task.Header> = raw.hdr
    st<task.State> = hdr.state
    st.ref_dec()
    jh.init(raw)

    bt<rtblk.BlockingTask> = rtblk.BlockingTask::new(op, raw)
    item<rtblk.BlockingTaskItem> = rtblk.BlockingTaskItem::new(bt, 0)
    err<i32> = sp.spawn(item)
    if err != 0 {
        jh.init(null)
    }
    return jh
}

// Run fut to completion via the active scheduler's block_on.
Handle::block_on(fut) i32, i64 {
    if this.sched_kind == 1 {
        // multi_thread does not own block_on directly; route through the
        // current_thread's caller. The runtime root's block_on shim
        // handles this dispatch.
        return RT_RUNTIME_SHUTDOWN, 0
    }
    ct<sched.CtHandle> = this.sched_handle.(sched.CtHandle)
    err<i32> = 0
    val<i64> = 0
    err, val = sched.block_on(ct, fut)
    return err, val
}
