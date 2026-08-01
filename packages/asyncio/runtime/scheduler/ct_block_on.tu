// block_on main loop. Wraps the user's future as a root task, then spins
// through Defer / Inject / Local until the root completes. When all
// queues are empty we ask the driver to park.

use runtime
use io
use sys
use asyncio.task
use asyncio.runtime as rt
use asyncio.runtime.io as rtio

// asyncio.error.RuntimeShutdown
SCHED_RUNTIME_SHUTDOWN<i32> = 0x03020005

// Tu passes RawTask* as ctx so
// ScheduledIo wake can RawTask::wake_by_ref without a (handle,id) lookup.
fn ct_task_ctx(t<task.RawTask>) u64 {
    return t.(u64)
}

// Run one polling round on raw via the harness vtable.
fn core_run_task(t<task.RawTask>, handle<CtHandle>){
    ctx<u64> = ct_task_ctx(t)
    task.harness_poll(t, ctx)
}

// Drain the Defer list back to inject. Defer hosts the tasks parked by
// coop yield_now; pushing them back to inject preserves FIFO across the
// next polling round.
fn drain_defer(defer<Defer>, inj<Inject>) i32 {
    if defer.is_empty() != 0 return 0
    defer.drain_into_inject(inj)
    return 1
}

// Close the runtime inject queue via raw CtHandle bits.
fn ct_inject_close(bits<u64>) {
    ct<CtHandle> = bits.(CtHandle)
    ct.shared.inject.close()
}

// block_on via raw CtHandle bits (for callers outside this package).
fn block_on_raw(bits<u64>, fut) i32, i64 {
    ct<CtHandle> = bits.(CtHandle)
    err<i32> = 0
    val<i64> = 0
    err, val = block_on(ct, fut)
    return err, val
}

// block_on with Future* passed as u64 (cross-pkg safe).
fn block_on_bits(handle_bits<u64>, fut_bits<u64>) i32, i64 {
    ct<CtHandle> = handle_bits.(CtHandle)
    fut<runtime.Future> = fut_bits.(runtime.Future)
    if fut == null {
    } else {
    }
    err<i32> = 0
    val<i64> = 0
    err, val = block_on(ct, fut)
    return err, val
}

fn ct_park_driver(shared<CtShared>, core_obj<Core>) {
    if shared.driver != 0 && shared.driver_handle != 0 {
        drv<rt.Driver> = shared.driver
        h<rt.DriverHandle> = shared.driver_handle
        drv.park(h)
        return
    }
    // Fallback: IO-only park when aggregate driver was not wired.
    iod<u64> = shared.iod_bits
    ioh<u64> = shared.ioh_bits
    if iod == 0 || ioh == 0 {
        runtime.osyield()
        return
    }
    iodrv<rtio.IoDriver> = iod.(rtio.IoDriver)
    ih<rtio.IoHandle> = ioh.(rtio.IoHandle)
    iodrv.turn(ih, sys.MAX)
}

// block_on the root future. Returns (err, value) once the root completes
// or RuntimeShutdown when the inject queue closed before the root did.
fn block_on(handle<CtHandle>, fut) (i32, i64) {
    shared<CtShared> = handle.shared
    fut_bits<u64> = 0
    fut_bits = fut
    root<task.RawTask> = task.bind_root(fut_bits, handle, ct_schedule_bridge.(u64), ct_release_bridge.(u64))

    core_obj<Core> = ct_core_new(shared.driver, DEFAULT_GLOBAL_QUEUE_INTERVAL)
    defer<Defer>   = Defer::new()
    ctx_obj<CtContext> = CtContext::new(handle, core_obj, defer)
    saved<CtSavedSlot> = ct_enter(ctx_obj)

    notif_root<task.Notified> = task.notified_from_raw(root)
    core_obj.push_local(root)

    err_out<i32> = 0
    val_out<i64> = 0

    loop {
        snap<i32> = root.life_load()
        if (snap & task.COMPLETE) != 0 {
            err_out = 0
            val_out = root.task_cell.peek_output()
            break
        }

        if drain_defer(defer, shared.inject) {
            continue
        }

        core_obj.tick = core_obj.tick + 1
        // Skip Inject::pop when empty: empty (NotFound, Notified) multi-ret
        // hangs / corrupts the dyn return ABI (layout). The design Option::None.
        if (core_obj.tick % core_obj.global_queue_interval) == 0 {
            if shared.inject.is_empty() == 0 {
                ierr<i32>, ti<task.Notified> = shared.inject.pop()
                if ierr == 0 {
                    raw_i<task.RawTask> = ti.raw()
                    core_run_task(raw_i, handle)
                    continue
                }
            }
        }

        lerr<i32>, tl<task.RawTask> = core_obj.pop_local()
        if lerr == 0 {
            core_run_task(tl, handle)
            continue
        }

        if shared.inject.is_empty() == 0 {
            ierr<i32>, ti<task.Notified> = shared.inject.pop()
            if ierr == 0 {
                raw_j<task.RawTask> = ti.raw()
                core_run_task(raw_j, handle)
                continue
            }
        }

        if shared.inject.is_closed() {
            err_out = SCHED_RUNTIME_SHUTDOWN
            break
        }

        ct_park_driver(shared, core_obj)
    }

    ct_exit(saved)
    return err_out, val_out
}
