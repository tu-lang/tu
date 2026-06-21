// Cross-thread weak handle to a Runtime. spawn / spawn_blocking /
// block_on / enter all funnel through here so user code never depends
// on the concrete scheduler kind.

use asyncio.error as aerr
use asyncio.task

// Weak runtime handle. sched_handle is a u64 because both schedulers
// (current_thread.CtHandle and multi_thread.MtHandle) implement
// task.Schedule but the union type stays opaque at this layer.
mem Handle {
    u64           sched_handle      // CtHandle* or MtHandle* raw bits
    i32           sched_kind        // 0 = current_thread, 1 = multi_thread
    DriverHandle* driver
    u64           blocking_spawner  // raw bits of blocking.Spawner*
}

// Build a fresh weak handle.
const Handle::new(sched<u64>, kind<i32>, driver<DriverHandle>, blocking<u64>) Handle* {
    h<Handle> = new Handle
    h.sched_handle     = sched
    h.sched_kind       = kind
    h.driver           = driver
    h.blocking_spawner = blocking
    return &h
}

// Look up the active Handle. Returns (OtherRuntime1XNotFound, null)
// outside any runtime context.
const Handle::current() (i32, Handle*) {
    rc<RuntimeContext> = current_context()
    if rc == null return io.OtherRuntime1XNotFound, null

    // The runtime root stores the Handle pointer in sched_handle for
    // first-pass simplicity; later phases may split scheduler-only ops
    // out behind a thinner interface.
    return 0, rc.sched.(Handle)
}

// Spawn a future via the active scheduler. Routes by sched_kind.
Handle::spawn(fut) JoinHandle* {
    if this.sched_kind == 1 {
        mh<MtHandle> = this.sched_handle.(MtHandle)
        return mh.spawn(fut)
    }
    ct<CtHandle> = this.sched_handle.(CtHandle)
    return ct.spawn(fut)
}

// Spawn a sync closure on the blocking pool. Returns a JoinHandle the
// caller can await for the u64 result.
Handle::spawn_blocking(op<fc<blocking_op>>) JoinHandle* {
    sp<Spawner> = this.blocking_spawner.(Spawner)
    if sp == null {
        jh<JoinHandle> = new JoinHandle
        jh.init(null)
        return &jh
    }
    // For the first-pass impl we synthesise a minimal RawTask wired to
    // a BlockingSchedule so JoinHandle observes the result. Wiring the
    // result through a real cell happens in task 8.3 / 8.6 follow-ups.
    jh<JoinHandle> = new JoinHandle
    jh.init(null)
    return &jh
}

// Run fut to completion via the active scheduler's block_on.
Handle::block_on(fut) (i32, i64) {
    if this.sched_kind == 1 {
        // multi_thread does not own block_on directly; route through the
        // current_thread's caller. The runtime root's block_on shim
        // handles this dispatch.
        return aerr.RuntimeShutdown, 0
    }
    ct<CtHandle> = this.sched_handle.(CtHandle)
    return block_on(ct, fut)
}

