// MtHandle is the cross-call-face entry point for the multi_thread
// scheduler. It impls task.Schedule so harness_complete and AbortHandle
// route through it; spawn wires a fresh task into OwnedTasks and pushes
// the Notified onto the calling worker's local queue (or inject).

use asyncio.task

// Cross-thread handle backing user-visible spawn / Schedule.
mem MtHandle {
    MtShared* shared
    u64       driver_handle      // raw bits of runtime.driver.Handle*
    u64       blocking_spawner   // raw bits of runtime.blocking.Spawner*
    u64       config             // raw bits of runtime.Config*
}

// Build a handle around shared.
const MtHandle::new(shared<MtShared>) MtHandle* {
    h<MtHandle> = new MtHandle
    h.shared           = shared
    h.driver_handle    = 0
    h.blocking_spawner = 0
    h.config           = 0
    return &h
}

// Schedule a Notified task. If the calling thread is a worker we push to
// its Local queue; otherwise we inject + notify_one. The "is current
// worker" check piggybacks on context.current_mt() once the runtime
// root is in place; for the first pass we always go through inject.
impl task.Schedule for MtHandle {
    fn schedule(t){
        notif<task.Notified> = t
        this.shared.inject.push(notif)

        // Wake one parked worker if any are sleeping.
        sn<MtSynced> = this.shared.synced
        found<i32>, idx<u32> = this.shared.idle.notify_one(sn.idle_synced, this.shared.synced_lock)
        if found == 1 && idx < this.shared.num_workers {
            r<Remote> = this.shared.remotes[idx]
            if r.unparker != null r.unparker.unpark()
        }
    }

    fn release(raw){
        this.shared.owned.remove(raw)
    }
}

// Spawn a future. Returns a JoinHandle*; the first Notified is enqueued
// via schedule().
MtHandle::spawn(fut) JoinHandle* {
    tid<task.TaskId> = task.alloc_id()
    raw<task.RawTask> = task.raw_new(fut, this, tid.v)
    err<i32> = this.shared.owned.bind(&raw)
    if err != 0 {
        jh<JoinHandle> = new JoinHandle
        jh.init(null)
        return &jh
    }
    notif<task.Notified> = task.notified_from_raw(&raw)
    this.schedule(notif)

    jh<JoinHandle> = new JoinHandle
    jh.init(&raw)
    return &jh
}

