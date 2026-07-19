// Worker main loop. Each worker thread runs worker_run, which pumps the
// LIFO slot, Local FIFO, periodic inject pull, and a steal phase before
// parking. State transitions through Idle make sure we never lose a
// wake-up: the last searcher always notifies one peer.

use runtime
use io
use asyncio.task

// Pack task pointer as future ctx (mother: waker data = Header*).
fn mt_task_ctx(t<task.RawTask>) u64 {
    return t.(u64)
}

// Periodic inject pull keeps fairness vs. the local queue.
fn mt_next_global_task(w<MtWorker>, core<WorkerCore>) (i32, task.Notified) {
    err<i32> = 0
    t<task.Notified> = task.notified_from_raw(null)
    err, t = w.handle.shared.inject.pop()
    return err, t
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
        if idx == w.worker_idx continue
        bits<u64> = shared.remotes[idx]
        r<Remote> = bits.(Remote)
        err<i32> = 0
        t<task.Notified> = task.notified_from_raw(null)
        err, t = r.steal_end.steal_into(core.run_queue)
        if err == 0 return 0, t
    }
    return io.NotFound, task.notified_from_raw(null)
}

// Run one task via the harness. Must be called outside any worker lock.
fn run_task(w<MtWorker>, core<WorkerCore>, t<task.Notified>){
    if core.is_searching == 1 {
        core.is_searching = 0
        last<i32> = w.handle.shared.idle.transition_worker_from_searching()
        if last == 1 {
            // Last searcher: keep the pipeline filled by waking another peer.
            sn<MtSynced> = w.handle.shared.lock_hub
            found<i32>, idx<u32> = w.handle.shared.idle.notify_one(sn.idle_synced, w.handle.shared.synced_lock)
            if found == 1 && idx < w.handle.shared.num_workers {
                bits2<u64> = w.handle.shared.remotes[idx]
                r<Remote> = bits2.(Remote)
                if r.unparker != null r.unparker.unpark()
            }
        }
    }
    raw<task.RawTask> = t.raw()
    ctx<u64> = mt_task_ctx(raw)
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

// Take the WorkerCore hand-off, then enter the typed loop body.
fn worker_run(w<MtWorker>){
    core_bits<u64> = w.core.take()
    if core_bits == 0 return
    worker_run_loop(w, core_bits.(WorkerCore))
}

// Loop body takes WorkerCore as a parameter so member access is typed.
// A local `core = bits.(WorkerCore)` does not (asmgen: undefined variable core.*).
fn worker_run_loop(w<MtWorker>, core<WorkerCore>){
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
            if shared.idle.transition_worker_to_searching() == 1 {
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
        is_last_searcher<i32> = 0
        if core.is_searching == 1 {
            is_last_searcher = shared.idle.transition_worker_from_searching()
            core.is_searching = 0
        }
        sn<MtSynced> = shared.lock_hub
        will_park<i32> = shared.idle.transition_worker_to_parked(
            sn.idle_synced, shared.synced_lock, w.worker_idx, is_last_searcher
        )
        if will_park == 0 continue

        core.parker.wait_until_wake(w.handle.driver_handle)
        shared.idle.transition_worker_from_parked(sn.idle_synced, shared.synced_lock, w.worker_idx)
        if shared.idle.transition_worker_to_searching() == 1 {
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

