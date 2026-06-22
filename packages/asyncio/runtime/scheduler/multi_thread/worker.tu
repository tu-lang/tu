// Worker main loop. Each worker thread runs worker_run, which pumps the
// LIFO slot, Local FIFO, periodic inject pull, and a steal phase before
// parking. State transitions through Idle make sure we never lose a
// wake-up: the last searcher always notifies one peer.

use runtime
use asyncio.task

// Pack (handle, task_id) into the future's ctx slot. Mirrors the
// current_thread version so harnesses observe the same shape.
fn ctx_pack(handle<MtHandle>, task_id<u64>) u64 {
    h_bits<u64> = handle.(u64)
    return (h_bits & 0xFFFFFFFF00000000) | (task_id & 0xFFFFFFFF)
}

// Periodic inject pull keeps fairness vs. the local queue.
fn mt_next_global_task(w<MtWorker>, core<WorkerCore>) (i32, task.Notified) {
    return w.handle.shared.inject.pop()
}

// Try to steal a batch of tasks. Returns one task to run immediately and
// places the rest in the worker's Local. Visits remotes in a randomised
// order via FastRand so multiple stealers don't dogpile the same victim.
fn mt_steal_work(w<MtWorker>, core<WorkerCore>) (i32, task.Notified) {
    shared<MtShared> = w.handle.shared
    n<u32> = shared.num_workers
    if n <= 1 return io.NotFound, task.notified_from_raw(null)

    start<u32> = core.rand.fastrand_n(n)
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (start + i) % n
        if idx == w.index continue
        r<Remote> = shared.remotes[idx].(Remote)
        err<i32>, t<task.Notified> = r.steal.steal_into(core.run_queue)
        if err == 0 return 0, t
    }
    return io.NotFound, task.notified_from_raw(null)
}

// Run one task via the harness. Must be called outside any worker lock.
fn run_task(w<MtWorker>, core<WorkerCore>, t<task.Notified>){
    if core.is_searching == 1 {
        core.is_searching = 0
        last<bool> = w.handle.shared.idle.transition_worker_from_searching()
        if last {
            // Last searcher: keep the pipeline filled by waking another peer.
            sn<MtSynced> = w.handle.shared.synced
            found<i32>, idx<u32> = w.handle.shared.idle.notify_one(sn.idle_synced, w.handle.shared.synced_lock)
            if found == 1 && idx < w.handle.shared.num_workers {
                r<Remote> = w.handle.shared.remotes[idx].(Remote)
                if r.unparker != null r.unparker.unpark()
            }
        }
    }
    raw<task.RawTask> = t.raw
    h<task.Header> = raw.hdr
    ctx<u64> = ctx_pack(w.handle, h.task_id)
    task.harness_poll(raw, ctx)
}

// Push the worker's Local FIFO back to inject so other workers can pick
// up its outstanding work after shutdown.
fn mt_pre_shutdown(w<MtWorker>, core<WorkerCore>){
    if core.lifo_slot != 0 {
        bits<u64> = core.lifo_slot
        core.lifo_slot = 0
        notif<task.Notified> = task.notified_from_raw(bits.(task.RawTask))
        w.handle.shared.inject.push(notif)
    }
    loop {
        err<i32>, t<task.Notified> = core.run_queue.pop()
        if err != 0 break
        w.handle.shared.inject.push(t)
    }
}

// Final shutdown bookkeeping: store the WorkerCore back so the runtime
// root can free it after every worker has exited.
fn mt_finalize_shutdown(w<MtWorker>, core<WorkerCore>){
    shared<MtShared> = w.handle.shared
    shared.shutdown_cores_lock.lock()
    if shared.shutdown_cores_len < shared.num_workers {
        shared.shutdown_cores[shared.shutdown_cores_len] = core.(u64)
        shared.shutdown_cores_len += 1
    }
    shared.shutdown_cores_lock.unlock()
}

// Worker main loop.
fn worker_run(w<MtWorker>){
    core_bits<u64> = w.core.take()
    if core_bits == 0 return
    core<WorkerCore> = core_bits.(WorkerCore)
    shared<MtShared> = w.handle.shared

    loop {
        if core.is_shutdown == 1 break
        core.tick = core.tick + 1

        // 1) Periodic inject pull.
        if (core.tick % core.global_queue_interval) == 0 {
            err<i32>, t<task.Notified> = mt_next_global_task(w, core)
            if err == 0 {
                run_task(w, core, t)
                continue
            }
        }

        // 2) LIFO slot.
        if core.lifo_slot != 0 {
            bits<u64> = core.lifo_slot
            core.lifo_slot = 0
            run_task(w, core, task.notified_from_raw(bits.(task.RawTask)))
            continue
        }

        // 3) Local FIFO.
        lerr<i32>, lt<task.Notified> = core.run_queue.pop()
        if lerr == 0 {
            run_task(w, core, lt)
            continue
        }

        // 4) Steal phase. Only enter searching state when the wheel
        // policy allows it (cap on concurrent searchers).
        if core.is_searching == 0 {
            if shared.idle.transition_worker_to_searching() {
                core.is_searching = 1
            }
        }
        if core.is_searching == 1 {
            serr<i32>, st<task.Notified> = mt_steal_work(w, core)
            if serr == 0 {
                run_task(w, core, st)
                continue
            }
        }

        // 5) Park. Drop searching state first so other workers can
        // start new searches on our behalf.
        is_last_searcher<bool> = false
        if core.is_searching == 1 {
            is_last_searcher = shared.idle.transition_worker_from_searching()
            core.is_searching = 0
        }
        sn<MtSynced> = shared.synced
        will_park<bool> = shared.idle.transition_worker_to_parked(
            sn.idle_synced, shared.synced_lock, w.index, is_last_searcher
        )
        if will_park == false continue

        core.park.park(w.handle.driver_handle)
        shared.idle.transition_worker_from_parked(sn.idle_synced, shared.synced_lock, w.index)
        if shared.idle.transition_worker_to_searching() {
            core.is_searching = 1
        }
    }

    mt_pre_shutdown(w, core)
    mt_finalize_shutdown(w, core)
}

// runtime.newcore entry-point. ACTIVE_WORKER is set by Builder before
// spawning the new core; the worker reads it on entry.
ACTIVE_WORKER<MtWorker> = null

fn worker_entry(){
    w<MtWorker> = ACTIVE_WORKER
    if w == null return
    worker_run(w)
}

