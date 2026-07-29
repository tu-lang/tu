// Worker main loop. Each worker thread runs worker_run, which pumps the
// LIFO slot, Local FIFO, periodic inject pull, and a steal phase before
// parking. State transitions through Idle make sure we never lose a
// wake-up: the last searcher always notifies one peer.

use runtime
use io
use asyncio.task
use asyncio.util as util

// Pack task pointer as future ctx.
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

    start<u32> = util.fastrand_n(core.rand, n)
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (start + i) % n
        if idx == w.worker_idx continue
        bits<u64> = shared.remotes[idx]
        if bits == 0 continue
        r<Remote> = bits.(Remote)
        if r.steal_end == null continue
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

// Block until every worker OS thread has left worker_entry.
fn mt_wait_workers(bits<u64>) {
    mh<MtHandle> = bits.(MtHandle)
    shared<MtShared> = mh.shared
    spins<i32> = 0
    loop {
        n<i32> = shared.workers_alive
        if n <= 0 {
            return
        }
        mt_notify_all_workers(shared)
        runtime.osyield()
        spins += 1
        // Safety valve: avoid hanging forever if a worker is stuck.
        if spins > 1000000 {
            return
        }
    }
}

// Take the WorkerCore hand-off, then enter the typed loop body.
fn worker_run(w<MtWorker>){
    core_bits<u64> = w.core.take()
    if core_bits == 0 { return }
    worker_run_loop(w, core_bits.(WorkerCore))
}

// Loop body takes WorkerCore as a parameter so member access is typed.
// Mother: enter_runtime around the worker run loop. Context is prebuilt on
// the builder thread — cross-package multi-arg fn-ptr enter SEGV'd on workers.
fn worker_run_loop(w<MtWorker>, core<WorkerCore>){
    shared<MtShared> = w.handle.shared
    saved_ctx<u64> = 0
    if w.ctx_bits != 0 {
        saved_ctx = mt_ctx_enter(w.ctx_bits)
    }
    // Bind core for future schedule_local; schedule still injects today.
    mt_core_bind(core.(u64))

    loop {
        if shared.inject.is_closed() {
            core.is_shutdown = 1
        }
        if core.is_shutdown == 1 break
        core.tick = core.tick + 1

        // 1) Periodic inject pull.
        if (core.tick % core.global_queue_interval) == 0 {
            err<i32>, t<task.Notified> = mt_next_global_task(w, core)
            if err == 0 {
                raw0<task.RawTask> = t.raw()
                if shared.block_on_root_bits == 0 || raw0.(u64) != shared.block_on_root_bits {
                    run_task(w, core, t)
                    continue
                }
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

        if shared.inject.is_empty() == 0 {
            ierr2<i32>, ti2<task.Notified> = mt_next_global_task(w, core)
            if ierr2 == 0 {
                raw_skip<task.RawTask> = ti2.raw()
                // Caller owns the block_on root — never poll it on a worker.
                if shared.block_on_root_bits != 0 {
                    if raw_skip.(u64) == shared.block_on_root_bits {
                        continue
                    }
                }
                run_task(w, core, ti2)
                continue
            }
        }

        // 5) Park. Matches Core::transition_to_parked.
        if shared.shutting_down == 1 {
            core.is_shutdown = 1
            continue
        }
        was_searching<i32> = core.is_searching
        sn<MtSynced> = shared.lock_hub
        is_last_searcher<i32> = shared.idle.transition_worker_to_parked(
            sn.idle_synced, shared.synced_lock, w.worker_idx, was_searching
        )
        core.is_searching = 0
        if is_last_searcher == 1 {
            mt_notify_if_work_pending(w)
        }

        core.parker.wait_until_wake(w.handle.driver_handle)
        if shared.shutting_down == 1 {
            core.is_shutdown = 1
            continue
        }
        shared.idle.transition_worker_from_parked(sn.idle_synced, shared.synced_lock, w.worker_idx)
        if shared.idle.transition_worker_to_searching() == 1 {
            core.is_searching = 1
        }
    }

    mt_pre_shutdown(w, core)
    mt_finalize_shutdown(w, core)

    mt_core_unbind()
    if saved_ctx != 0 {
        mt_ctx_exit(saved_ctx)
    }
}

// Last searcher leaving search: if inject still has work, wake one sleeper.
fn mt_notify_if_work_pending(w<MtWorker>){
    shared<MtShared> = w.handle.shared
    if shared.inject.is_empty() != 0 {
        return
    }
    sn<MtSynced> = shared.lock_hub
    found<i32>, idx<u32> = shared.idle.notify_one(sn.idle_synced, shared.synced_lock)
    if found == 1 && idx < shared.num_workers {
        bits2<u64> = shared.remotes[idx]
        r<Remote> = bits2.(Remote)
        if r.unparker != null r.unparker.unpark()
    }
}

// Handoff so each newcore claims exactly one MtWorker (avoids the
// ACTIVE_WORKER overwrite race when spawning N workers in a loop).
// Heap hub — package-level MutexInter* globals poison codegen.
mem WorkerHandoffHub {
    runtime.MutexInter* lock
    MtWorker* slot
}

WORKER_HANDOFF<WorkerHandoffHub> = null

fn worker_handoff_ensure(){
    if WORKER_HANDOFF != null {
        return
    }
    // Only the builder thread may create the hub (before any newcore).
    h<WorkerHandoffHub> = new WorkerHandoffHub
    h.lock = new runtime.MutexInter
    h.lock.init()
    h.slot = null
    WORKER_HANDOFF = h
}

// Must be called from the builder thread before the first newcore.
fn worker_handoff_init(){
    worker_handoff_ensure()
}

// Builder publishes the next worker then waits until the OS thread claims it.
fn worker_handoff_publish(w<MtWorker>){
    worker_handoff_ensure()
    h<WorkerHandoffHub> = WORKER_HANDOFF
    loop {
        h.lock.lock()
        if h.slot == null {
            h.slot = w
            h.lock.unlock()
            return
        }
        h.lock.unlock()
        runtime.osyield()
    }
}

// Block until the published worker has been claimed by worker_entry.
fn worker_handoff_wait_claimed(){
    worker_handoff_ensure()
    h<WorkerHandoffHub> = WORKER_HANDOFF
    loop {
        h.lock.lock()
        done<i32> = 0
        if h.slot == null {
            done = 1
        }
        h.lock.unlock()
        if done == 1 {
            return
        }
        runtime.osyield()
    }
}

// runtime.newcore entry-point: claim the published MtWorker.
fn worker_entry(){
    h<WorkerHandoffHub> = WORKER_HANDOFF
    if h == null {
        return
    }
    w<MtWorker> = null
    loop {
        h.lock.lock()
        if h.slot != null {
            w = h.slot
            h.slot = null
            h.lock.unlock()
            break
        }
        h.lock.unlock()
        runtime.osyield()
    }
    if w == null {
        return
    }
    shared0<MtShared> = w.handle.shared
    // Increment before run; builder's wait_claimed already saw the claim.
    shared0.workers_alive += 1
    worker_run(w)
    shared0.workers_alive -= 1
}

