// Worker main loop. Each worker thread runs worker_run, which pumps the
// LIFO slot, Local FIFO, periodic inject pull, and a steal phase before
// parking. State transitions through Idle make sure we never lose a
// wake-up: the last searcher always notifies one peer.

use runtime
use std.atomic
use io
use sys
use asyncio.task
use asyncio.util as util
use asyncio.runtime as asyncrt


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
// WorkerCore is already bound via mt_core_bind for the loop lifetime;
// spawn/schedule_local reads it through mt_core_current_bits.
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
    // Mother wraps each task poll in coop::budget.
    asyncrt.reset_budget()
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

// Block until every MT worker OS thread has exited (CLEARTID on Core.clear_tid).
// mt_inject_close already notified; do not re-notify here.
fn mt_join_os_workers(bits<u64>) {
    handle<MtHandle> = bits.(MtHandle)
    shared<MtShared> = handle.shared
    i<u32> = 0
    while i < shared.os_cores_len {
        cb<u64> = shared.os_cores[i]
        if cb != 0 {
            runtime.core_join(cb)
            shared.os_cores[i] = 0
        }
        i += 1
    }
}

fn mt_wait_workers(bits<u64>) {
    mt_join_os_workers(bits)
}

// Take the WorkerCore hand-off, then enter the typed loop body.
fn worker_run(w<MtWorker>){
    core_bits<u64> = w.core.take()
    if core_bits == 0 { return }
    worker_run_loop(w, core_bits.(WorkerCore))
}

// Loop body takes WorkerCore as a parameter so member access is typed.
// Mother: enter_runtime around the worker run loop — build context on
// this thread via direct cross-pkg call, then mt_ctx_enter.
fn worker_run_loop(w<MtWorker>, core<WorkerCore>){
    shared<MtShared> = w.handle.shared
    ctx_bits<u64> = asyncrt.mt_worker_ctx_prebuild(
        w.handle.(u64),
        w.handle.rt_handle,
        w.handle.driver_handle,
        core.rand.(u64)
    )
    saved_ctx<u64> = mt_ctx_enter(ctx_bits)
    // Bind WorkerCore so spawn and wake both prefer schedule_local.
    mt_core_bind(core.(u64))
    ran_since_turn<u32> = 0
    ev_i<u32> = core.event_interval
    if ev_i == 0.(u32) {
        ev_i = 61
    }

    loop {
        // Prefer unlocked shutting_down — inject.is_closed() takes gate_lock
        // every iteration and contended with push/pop under load.
        if shared.shutting_down == 1 {
            core.is_shutdown = 1
        }
        if core.is_shutdown == 1 break
        core.tick = core.tick + 1
        core.progress = core.progress + 1

        // Mother Context::maintenance: after event_interval *task runs*,
        // non-blocking driver turn (not every empty steal spin).
        if ran_since_turn >= ev_i {
            zero<sys.Duration> = sys.Duration::from_millis(0)
            core.parker.park_timeout(w.handle.driver_handle, zero)
            ran_since_turn = 0
        }

        // Cooperative GC while busy (park path already osyields).
        if (core.tick % core.global_queue_interval) == 0 {
            runtime.osyield()
        }

        // 1) Periodic inject pull.
        if (core.tick % core.global_queue_interval) == 0 {
            err<i32>, t<task.Notified> = mt_next_global_task(w, core)
            if err == 0 {
                run_task(w, core, t)
                ran_since_turn += 1
                continue
            }
        }

        // 2) LIFO slot.
        if core.lifo_slot != 0 {
            bits<u64> = core.lifo_slot
            core.lifo_slot = 0
            run_task(w, core, task.notified_from_raw(bits.(task.RawTask)))
            ran_since_turn += 1
            continue
        }

        // 3) Local FIFO.
        lerr<i32>, lt<task.Notified> = core.run_queue.pop()
        if lerr == 0 {
            run_task(w, core, lt)
            ran_since_turn += 1
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
                ran_since_turn += 1
                continue
            }
        }

        if shared.inject.is_empty() == 0 {
            ierr2<i32>, ti2<task.Notified> = mt_next_global_task(w, core)
            if ierr2 == 0 {
                run_task(w, core, ti2)
                ran_since_turn += 1
                continue
            }
        }

        // 5) Park. Drain lifo + one local pop first (LIFO is not stealable).
        // Never gate on Local::len() (steal races → 100% spin). Mother
        // notify uses unpark_one(+unparked,+searching); wake path matches
        // transition_from_parked.
        if shared.shutting_down == 1 {
            core.is_shutdown = 1
            continue
        }
        if core.lifo_slot != 0 {
            bits_pre<u64> = core.lifo_slot
            core.lifo_slot = 0
            run_task(w, core, task.notified_from_raw(bits_pre.(task.RawTask)))
            ran_since_turn += 1
            continue
        }
        lerr_pre<i32>, lt_pre<task.Notified> = core.run_queue.pop()
        if lerr_pre == 0 {
            run_task(w, core, lt_pre)
            ran_since_turn += 1
            continue
        }
        // Inject may have work while local is empty (mother next_task).
        if shared.inject.is_empty() == 0 {
            ierr_pre<i32>, ti_pre<task.Notified> = mt_next_global_task(w, core)
            if ierr_pre == 0 {
                run_task(w, core, ti_pre)
                ran_since_turn += 1
                continue
            }
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
        // Push-vs-park: still in sleepers → unpark_worker_by_id credits.
        // If notify already popped us (return 0), searching was +1'd — we are
        // the searcher (mother transition_from_parked has_tasks path).
        if core.lifo_slot != 0 {
            was_lf<i32> = shared.idle.unpark_worker_by_id(sn.idle_synced, shared.synced_lock, w.worker_idx)
            if was_lf == 0 {
                core.is_searching = 1
            }
            continue
        }
        if shared.inject.is_empty() == 0 {
            ierr_pk0<i32>, ti_pk0<task.Notified> = mt_next_global_task(w, core)
            if ierr_pk0 == 0 {
                was_inj<i32> = shared.idle.unpark_worker_by_id(sn.idle_synced, shared.synced_lock, w.worker_idx)
                if was_inj == 0 {
                    core.is_searching = 1
                }
                run_task(w, core, ti_pk0)
                ran_since_turn += 1
                continue
            }
        }

        // Park loop: mother transition_from_parked — leave only when local
        // has work or notify removed us from sleepers. Also pull inject:
        // schedule during park_driver can land on inject when searching
        // throttle skipped notify; without this check the driver re-parks
        // and SEARCHING_LEAK deadlocks (inject stranded, sleepers full).
        loop {
            // Refresh tid→core bind before park (claim if missing). IO wakes
            // during park_driver use mt_core_current_bits → this core's LIFO.
            mt_core_bind(core.(u64))
            core.parker.wait_until_wake(w.handle.driver_handle)
            core.progress = core.progress + 1
            if shared.shutting_down == 1 {
                core.is_shutdown = 1
                // Notify may have already +searching for us; drop that credit.
                if shared.idle.unpark_worker_by_id(sn.idle_synced, shared.synced_lock, w.worker_idx) == 0 {
                    if core.is_searching == 0 {
                        shared.idle.transition_worker_from_searching()
                    }
                }
                break
            }
            // Work scheduled onto this worker during park_driver.
            if core.lifo_slot != 0 {
                was_parked<i32> = shared.idle.unpark_worker_by_id(
                    sn.idle_synced, shared.synced_lock, w.worker_idx
                )
                // was_parked==0 ⇒ notify already +1 searching ⇒ we are searcher.
                if was_parked == 0 {
                    core.is_searching = 1
                } else {
                    core.is_searching = 0
                }
                break
            }
            lerr_pk<i32>, lt_pk<task.Notified> = core.run_queue.pop()
            if lerr_pk == 0 {
                was_parked2<i32> = shared.idle.unpark_worker_by_id(
                    sn.idle_synced, shared.synced_lock, w.worker_idx
                )
                if was_parked2 == 0 {
                    core.is_searching = 1
                } else {
                    core.is_searching = 0
                }
                run_task(w, core, lt_pk)
                ran_since_turn += 1
                break
            }
            if shared.inject.is_empty() == 0 {
                ierr_pk<i32>, ti_pk<task.Notified> = mt_next_global_task(w, core)
                if ierr_pk == 0 {
                    was_parked3<i32> = shared.idle.unpark_worker_by_id(
                        sn.idle_synced, shared.synced_lock, w.worker_idx
                    )
                    if was_parked3 == 0 {
                        core.is_searching = 1
                    } else {
                        core.is_searching = 0
                    }
                    run_task(w, core, ti_pk)
                    ran_since_turn += 1
                    break
                }
            }
            if shared.idle.is_parked(sn.idle_synced, shared.synced_lock, w.worker_idx) == 1 {
                continue
            }
            // Removed by notify_one: state already accounted via unpark_one.
            core.is_searching = 1
            break
        }
    }

    mt_pre_shutdown(w, core)
    mt_finalize_shutdown(w, core)

    mt_core_unbind()
    mt_ctx_exit(saved_ctx)
}

// Last searcher leaving search: if inject or any remote steal queue still
// has work, wake one sleeper (mother notify_if_work_pending).
fn mt_notify_if_work_pending(w<MtWorker>){
    shared<MtShared> = w.handle.shared
    pending<i32> = 0
    if shared.inject.is_empty() == 0 {
        pending = 1
    }
    if pending == 0 {
        n<u32> = shared.num_workers
        i<u32> = 0
        while i < n {
            bits<u64> = shared.remotes[i]
            if bits != 0 {
                r<Remote> = bits.(Remote)
                if r.steal_end != null && r.steal_end.is_empty() == 0 {
                    pending = 1
                    break
                }
            }
            i += 1
        }
    }
    if pending == 0 {
        return
    }
    sn<MtSynced> = shared.lock_hub
    found<i32>, idx<u32> = shared.idle.notify_one(sn.idle_synced, shared.synced_lock)
    if found == 1 && idx < shared.num_workers {
        bits2<u64> = shared.remotes[idx]
        r2<Remote> = bits2.(Remote)
        if r2.unparker != null r2.unparker.unpark()
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
    atomic.xadd(&shared0.workers_alive, 1)
    worker_run(w)
    // u32 all-ones: -1.(i8) zero-extends to +255 on xadd (see optimize atomic-xadd).
    dec_alive<u32> = 4294967295
    atomic.xadd(&shared0.workers_alive, dec_alive)
}

