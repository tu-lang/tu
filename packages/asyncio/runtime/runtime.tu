// Strong-side Runtime owner. shutdown_*  calls are idempotent and
// release the held drivers + blocking pool. Runtime::handle returns a
// weak Handle suitable for cloning across threads.

use sys
use fmt
use asyncio.task
use asyncio.util as util
use asyncio.runtime.scheduler
use asyncio.runtime.blocking as rtblk

KIND_CURRENT_THREAD<i32> = 0
KIND_MULTI_THREAD<i32>   = 1

// Strong owner of every long-lived runtime resource.
mem Runtime {
    i32           sched_kind
    Handle*       weak_handle
    DriverHandle* driver_handle
    Driver*       agg_drv           // not `driver` — `.driver` is a type-assert trap
    rtblk.Spawner*      blocking_spawner
    rtblk.BlockingPool* blocking_pool
    u64           scheduler_handle    // raw bits of CtHandle* / MtHandle*
    i32           shutdown_state      // 0 = running, 1 = shutting down, 2 = done
}

// Build a Runtime from already-composed pieces. Builder::build does the
// composition; this constructor is package-internal.
const Runtime::compose(
    kind<i32>,
    weak<Handle>,
    drv<Driver>,
    drv_h<DriverHandle>,
    sp<rtblk.Spawner>,
    pool<rtblk.BlockingPool>,
    sched<u64>
) Runtime {
    r<Runtime> = new Runtime
    r.sched_kind       = kind
    r.weak_handle      = weak
    r.agg_drv          = drv
    r.driver_handle    = drv_h
    r.blocking_spawner = sp
    r.blocking_pool    = pool
    r.scheduler_handle = sched
    r.shutdown_state   = 0
    return r
}

fn runtime_from_bits(bits<u64>) Runtime {
    return bits.(Runtime)
}

// TimeHandle bits for Sleep registration (package fn avoids member-call traps).
fn runtime_sleep_time_bits(rtv<Runtime>) u64 {
    if rtv == null return 0
    hdl<DriverHandle> = rtv.driver_handle
    if hdl == null return 0
    return hdl.time_bits()
}

fn runtime_to_bits(r<Runtime>) u64 {
    return r.(u64)
}

// Cheap weak handle clone.
Runtime::handle() Handle {
    return this.weak_handle
}

// Mother: runtime::context::enter_runtime before driving the future so
// Handle::current / PollEvented registration see the active driver.
// FastRand is required for select! fairness (select_start); null rng
// makes every select always start at branch 0.
fn runtime_enter_block_on(wh<Handle>) RtSavedSlot {
    drv_bits<u64> = 0
    sched_bits<u64> = 0
    if wh != null {
        sched_bits = wh.sched_handle
        d<DriverHandle> = wh.drv_h
        if d != null {
            drv_bits = d
        }
    }
    rng<util.FastRand> = util.FastRand::new(0xc0ffee)
    ctx<RuntimeContext> = RuntimeContext::new(
        sched_bits,
        drv_bits,
        rng,
        ENTER_BLOCK_ON
    )
    return rt_enter(ctx)
}

// Run fut to completion. multi_thread routes through a current_thread
// driver since block_on is inherently single-threaded.
Runtime::block_on(fut) i32, i64 {
    saved<RtSavedSlot> = runtime_enter_block_on(this.weak_handle)
    err2<i32> = 0
    val2<i64> = 0
    if this.sched_kind == KIND_CURRENT_THREAD {
        err2, val2 = scheduler.block_on_raw(this.scheduler_handle, fut)
    } else {
        err2, val2 = handle_block_on_impl(this.weak_handle, fut)
    }
    rt_exit(saved)
    return err2, val2
}

// Same as block_on but takes Future* bits — safe across package boundaries
// where a dynamic fut argument is dropped/nulled by codegen.
Runtime::block_on_bits(fut_bits<u64>) i32, i64 {
    saved<RtSavedSlot> = runtime_enter_block_on(this.weak_handle)
    err<i32> = 0
    val<i64> = 0
    if this.sched_kind == KIND_CURRENT_THREAD {
        err, val = scheduler.block_on_bits(this.scheduler_handle, fut_bits)
    } else {
        err, val = scheduler.block_on_bits(this.weak_handle.sched_handle, fut_bits)
    }
    rt_exit(saved)
    return err, val
}

// Spawn a future via the active scheduler.
Runtime::spawn(fut) task.JoinHandle {
    return handle_spawn_impl(this.weak_handle, fut)
}

// Spawn a blocking closure.
Runtime::spawn_blocking(op<u64>) task.JoinHandle {
    return handle_blocking_impl(this.weak_handle, op, 0)
}

// Shutdown with a deadline; idempotent. First call closes the inject
// queues, signals shutdown to the blocking pool, and tears down the
// driver. Second call is a no-op so safe to invoke from Drop-like sites.
Runtime::shutdown_timeout(d<sys.Duration>){
    if this.shutdown_state == 2 { return }
    this.shutdown_state = 1
    if this.sched_kind == KIND_CURRENT_THREAD {
        scheduler.ct_inject_close(this.scheduler_handle)
    } else {
        scheduler.mt_inject_close(this.scheduler_handle)
    }
    if this.blocking_pool != null this.blocking_pool.shutdown()
    if this.agg_drv != null this.agg_drv.shutdown(this.driver_handle)
    this.shutdown_state = 2
}

// Background variant: shutdown without a hard deadline. Same semantics.
Runtime::shutdown_background(){
    if this.shutdown_state == 2 { return }
    this.shutdown_state = 1
    if this.sched_kind == KIND_CURRENT_THREAD {
        scheduler.ct_inject_close(this.scheduler_handle)
    } else {
        scheduler.mt_inject_close(this.scheduler_handle)
    }
    if this.blocking_pool != null this.blocking_pool.shutdown()
    if this.agg_drv != null this.agg_drv.shutdown(this.driver_handle)
    this.shutdown_state = 2
}
