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
    u64       rt_handle          // raw bits of weak runtime.Handle*
}

// Build a handle around shared.
const MtHandle::new(shared<MtShared>) MtHandle {
    h<MtHandle> = new MtHandle
    h.shared           = shared
    h.driver_handle    = 0
    h.blocking_spawner = 0
    h.config           = 0
    h.rt_handle        = 0
    return h
}

// Push onto this worker's LIFO / Local (mother schedule_local).
// is_yield != 0 forces FIFO push (no LIFO).
// Caller must pass a typed WorkerCore (from stack / current_bits after GC-scanned bind).
fn mt_schedule_local(core<WorkerCore>, shared<MtShared>, notif<task.Notified>, is_yield<i32>) {
    should_notify<i32> = 0
    if is_yield != 0 || core.lifo_enabled == 0 {
        core.run_queue.push_back_or_overflow(notif, shared.inject)
        should_notify = 1
    } else {
        prev<u64> = core.lifo_slot
        if prev != 0 {
            should_notify = 1
            core.run_queue.push_back_or_overflow(
                task.notified_from_raw(prev.(task.RawTask)),
                shared.inject
            )
        }
        core.lifo_slot = notif.raw().(u64)
    }
    // Mother: notify only when work was spilled / FIFO push. Same-worker LIFO
    // with empty prev does not wake peers — this worker runs lifo next.
    if should_notify == 1 {
        sn<MtSynced> = shared.lock_hub
        found<i32>, idx<u32> = shared.idle.notify_one(sn.idle_synced, shared.synced_lock)
        if found == 1 && idx < shared.num_workers {
            rb<u64> = shared.remotes[idx]
            r<Remote> = rb.(Remote)
            if r.unparker != null {
                r.unparker.unpark()
            }
        }
    }
}

// Inject + wake one sleeper (mother push_remote_task + notify_parked_remote).
fn mt_schedule_remote(shared<MtShared>, notif<task.Notified>) {
    shared.inject.push(notif)
    sn<MtSynced> = shared.lock_hub
    found<i32>, idx<u32> = shared.idle.notify_one(sn.idle_synced, shared.synced_lock)
    if found == 1 && idx < shared.num_workers {
        rb<u64> = shared.remotes[idx]
        r<Remote> = rb.(Remote)
        if r.unparker != null {
            r.unparker.unpark()
        }
    }
}

// Prefer schedule_local when this OS thread holds a WorkerCore
// (mother with_current). Else inject.
fn mt_schedule_any(h<MtHandle>, notif<task.Notified>, is_yield<i32>, allow_local<i32>) {
    if allow_local != 0 {
        core_bits<u64> = mt_core_current_bits()
        if core_bits != 0 {
            core<WorkerCore> = core_bits.(WorkerCore)
            mt_schedule_local(core, h.shared, notif, is_yield)
            return
        }
    }
    mt_schedule_remote(h.shared, notif)
}

// Schedule a Notified task. Same as mother: local when on a worker, else inject.
impl task.Schedule for MtHandle {
    fn schedule(t){
        notif<task.Notified> = t
        mt_schedule_any(this, notif, 0, 1)
    }

    fn release(raw){
        this.shared.owned.remove(raw)
    }
}

// Close the runtime inject queue via raw MtHandle bits and wake every
// worker so they observe is_closed and exit (Handle::close + notify_all).
fn mt_inject_close(bits<u64>) {
    mh<MtHandle> = bits.(MtHandle)
    mh.shared.shutting_down = 1
    mh.shared.inject.close()
    mt_notify_all_workers(mh.shared)
}

// Unpark every remote worker (shutdown / inject close).
// Snapshot unparker then call — avoid chasing a field cleared mid-call.
fn mt_notify_all_workers(shared<MtShared>) {
    if shared == null {
        return
    }
    i<u32> = 0
    while i < shared.num_workers {
        rb<u64> = shared.remotes[i]
        if rb != 0 {
            r<Remote> = rb.(Remote)
            up<Unparker> = r.unparker
            if up != null {
                up.unpark()
            }
        }
        i += 1
    }
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

// Enqueue a freshly spawned Notified (local when worker holds a core).
fn mt_spawn_schedule(h<MtHandle>, notif<task.Notified>) {
    mt_schedule_any(h, notif, 0, 1)
}

// Package-level spawn entry (avoids mh.spawn parser trap).
fn mt_handle_spawn_fut(h<MtHandle>, fut) task.JoinHandle {
    tid<task.TaskId> = task.alloc_id()
    fut_bits<u64> = 0
    fut_bits = fut
    raw<task.RawTask> = task.raw_new(fut_bits, h, mt_schedule_bridge.(u64), mt_release_bridge.(u64), tid.v)
    err<i32> = h.shared.owned.bind(raw)
    if err != 0 {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }
    notif<task.Notified> = task.notified_from_raw(raw)
    mt_spawn_schedule(h, notif)

    jh2<task.JoinHandle> = new task.JoinHandle
    jh2.init(raw)
    return jh2
}

MtHandle::spawn(fut) task.JoinHandle {
    return mt_handle_spawn_fut(this, fut)
}

fn mt_schedule_bridge(hbits<u64>, nbits<u64>){
    mh<MtHandle> = hbits.(MtHandle)
    n<task.Notified> = nbits.(task.Notified)
    // Wake path: local when on a worker (same as Schedule::schedule).
    mt_schedule_any(mh, n, 0, 1)
}

fn mt_release_bridge(hbits<u64>, rbits<u64>){
    mh<MtHandle> = hbits.(MtHandle)
    rtask<task.RawTask> = rbits.(task.RawTask)
    mh.shared.owned.remove(rtask)
}
