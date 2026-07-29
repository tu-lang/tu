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

// Spawn-during-poll schedule_local (mother Handle::schedule_local).
// LIFO via interior &lifo_slot (atomic); spilled prev → inject (Local from
// TLS cast SEGV'd). Spawn path always is_yield=0.
fn mt_schedule_local(shared<MtShared>, notif<task.Notified>, is_yield<i32>) {
    should_notify<i32> = 0
    if is_yield != 0 {
        shared.inject.push(notif)
        should_notify = 1
    } else {
        prev<u64> = mt_poll_lifo_swap(notif.raw().(u64))
        if prev != 0 {
            should_notify = 1
            shared.inject.push(task.notified_from_raw(prev.(task.RawTask)))
        }
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

// Schedule a Notified task. Workers push local / LIFO; foreign callers
// inject + wake. block_on root wake only unparks the caller.
impl task.Schedule for MtHandle {
    fn schedule(t){
        notif<task.Notified> = t
        raw_bits<u64> = notif.raw().(u64)

        // block_on root wake: park.unpark only (do not inject).
        if this.shared.block_on_root_bits != 0 {
            if raw_bits == this.shared.block_on_root_bits {
                up0<Unparker> = this.shared.block_on_unparker
                if up0 != null {
                    up0.unpark()
                }
                return
            }
        }

        // Wakes / remote: inject. Spawn-during-poll uses mt_spawn_schedule
        // (schedule_local) — never cast WorkerCore inside this api method.
        mt_schedule_remote(this.shared, notif)
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
fn mt_notify_all_workers(shared<MtShared>) {
    i<u32> = 0
    while i < shared.num_workers {
        rb<u64> = shared.remotes[i]
        if rb != 0 {
            r<Remote> = rb.(Remote)
            if r.unparker != null {
                r.unparker.unpark()
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

// Enqueue a freshly spawned Notified.
// If this OS thread is inside run_task (poll-scoped &lifo_slot), mother
// schedule_local; otherwise inject (block_on thread / foreign).
fn mt_spawn_schedule(h<MtHandle>, notif<task.Notified>) {
    if mt_poll_lifo_ptr_bits() != 0 {
        mt_schedule_local(h.shared, notif, 0)
        return
    }
    h.schedule(notif)
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
    mh.schedule(n)
}

fn mt_release_bridge(hbits<u64>, rbits<u64>){
    mh<MtHandle> = hbits.(MtHandle)
    rtask<task.RawTask> = rbits.(task.RawTask)
    mh.shared.owned.remove(rtask)
}
