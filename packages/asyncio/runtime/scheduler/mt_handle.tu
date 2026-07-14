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
const MtHandle::new(shared<MtShared>) MtHandle {
    h<MtHandle> = new MtHandle
    h.shared           = shared
    h.driver_handle    = 0
    h.blocking_spawner = 0
    h.config           = 0
    return h
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
        sn<MtSynced> = this.shared.lock_hub
        found<i32>, idx<u32> = this.shared.idle.notify_one(sn.idle_synced, this.shared.synced_lock)
        if found == 1 && idx < this.shared.num_workers {
            rb<u64> = this.shared.remotes[idx]
            r<Remote> = rb.(Remote)
            if r.unparker != null r.unparker.unpark()
        }
    }

    fn release(raw){
        this.shared.owned.remove(raw)
    }
}

// Close the runtime inject queue via raw MtHandle bits.
fn mt_inject_close(bits<u64>) {
    mh<MtHandle> = bits.(MtHandle)
    mh.shared.inject.close()
}

// Raw-bits inject lookup for callers outside this package.
fn mt_sched_inject(bits<u64>) Inject* {
    mh<MtHandle> = bits.(MtHandle)
    return mh.shared.inject
}

// Raw-bits spawn entry for callers outside this package.
fn mt_handle_spawn_raw(bits<u64>, fut) task.JoinHandle {
    mh<MtHandle> = bits.(MtHandle)
    return mt_handle_spawn_fut(mh, fut)
}

// Package-level spawn entry (avoids mh.spawn parser trap).
fn mt_handle_spawn_fut(h<MtHandle>, fut) task.JoinHandle {
    tid<task.TaskId> = task.alloc_id()
    raw<task.RawTask> = task.raw_new(fut, h, tid.v)
    err<i32> = h.shared.owned.bind(raw)
    if err != 0 {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }
    notif<task.Notified> = task.notified_from_raw(raw)
    h.schedule(notif)

    jh2<task.JoinHandle> = new task.JoinHandle
    jh2.init(raw)
    return jh2
}

// Spawn a future. Returns a JoinHandle; the first Notified is enqueued
// via schedule(). raw_new returns a heap RawTask; pass it through.
MtHandle::spawn(fut) task.JoinHandle {
    return mt_handle_spawn_fut(this, fut)
}

