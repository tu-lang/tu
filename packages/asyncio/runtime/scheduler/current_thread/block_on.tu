// block_on main loop. Wraps the user's future as a root task, then spins
// through Defer / Inject / Local until the root completes. When all
// queues are empty we ask the driver to park; current_thread.Driver
// integration lands in Phase 10 — for now we fall back to a yield loop.

use runtime
use io
use asyncio.task
use asyncio.error as aerr

// Pack (handle, task_id) into one u64 for the future's ctx slot. High 32
// bits = scheduler handle hash, low 32 bits = task id (truncated).
fn ctx_pack(handle<CtHandle>, task_id<u64>) u64 {
    h_bits<u64> = handle.(u64)
    return (h_bits & 0xFFFFFFFF00000000) | (task_id & 0xFFFFFFFF)
}

// Run one polling round on raw via the harness vtable.
fn core_run_task(t<task.RawTask>, handle<CtHandle>){
    h_hdr<task.Header> = t.hdr
    ctx<u64> = ctx_pack(handle, h_hdr.task_id)
    task.harness_poll(t, ctx)
}

// Drain the Defer list back to inject. Defer hosts the tasks parked by
// coop yield_now; pushing them back to inject preserves FIFO across the
// next polling round.
fn drain_defer(defer<Defer>, inj<Inject>) bool {
    if defer.is_empty() return false
    defer.drain_into_inject(inj)
    return true
}

// block_on the root future. Returns (err, value) once the root completes
// or RuntimeShutdown when the inject queue closed before the root did.
fn block_on(handle<CtHandle>, fut) (i32, i64) {
    shared<CtShared> = handle.shared
    sched_obj<task.Schedule> = handle

    // Wrap fut as a root task; bind_root drops one ref so refcount = 2
    // (block_on + queue), without binding into OwnedTasks.
    root<task.RawTask> = task.bind_root(fut, sched_obj)

    core_obj<Core> = Core::new(0, DEFAULT_GLOBAL_QUEUE_INTERVAL)
    defer<Defer>   = Defer::new()
    ctx_obj<CtContext> = CtContext::new(handle, core_obj, defer)
    saved<CtSavedSlot> = ct_enter(ctx_obj)

    // Initial schedule: the root task starts on the local queue.
    notif_root<task.Notified> = task.notified_from_raw(&root)
    core_obj.push_local(&root)

    err_out<i32> = 0
    val_out<i64> = 0

    loop {
        // Check root completion before doing more work.
        h_hdr<task.Header> = root.hdr
        st<task.State>     = h_hdr.state
        snap<i32>          = st.load()
        if (snap & task.COMPLETE) != 0 {
            vt<task.RawVTable> = root.vtable
            fc<task.vtable_try_read_output> = vt.try_read_output.(u64)
            err_out, val_out = fc(&root)
            break
        }

        // Defer first so yield_now wakers fire ahead of newly pushed tasks.
        if drain_defer(defer, shared.inject) {
            continue
        }

        // Periodic inject pull keeps fairness vs. local queue.
        core_obj.tick = core_obj.tick + 1
        if (core_obj.tick % core_obj.global_queue_interval) == 0 {
            ierr<i32>, ti<task.Notified> = shared.inject.pop()
            if ierr == 0 {
                core_run_task(ti.raw, handle)
                continue
            }
        }

        // Local FIFO.
        lerr<i32>, tl<task.RawTask*> = core_obj.pop_local()
        if lerr == 0 {
            core_run_task(tl, handle)
            continue
        }

        // Inject as a fallback; if it's empty too we have to park.
        ierr<i32>, ti<task.Notified> = shared.inject.pop()
        if ierr == 0 {
            core_run_task(ti.raw, handle)
            continue
        }

        // All queues empty. If inject is closed we cannot make progress.
        if shared.inject.is_closed() {
            err_out = aerr.RuntimeShutdown
            break
        }

        // Park placeholder: yield to the OS and re-check the queues. block_on
        // is a plain fn (not async), so it cannot await; the real driver
        // (Phase 10) will block on shared.woken instead of spinning.
        runtime.osyield()
    }

    ct_exit(saved)
    return err_out, val_out
}

