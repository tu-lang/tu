// Per-thread RuntimeContext (tid table in scheduler/mt_ctx.tu).

use asyncio.util
use asyncio.runtime.scheduler as rtsched

ENTER_RUNTIME<i32> = 0
ENTER_BLOCK_ON<i32> = 1
ENTER_BLOCKING<i32> = 2

mem RuntimeContext {
    u64        sched
    u64        wh_bits
    u64        drv_bits
    util.FastRand*  rng
    i32        coop_budget
    i32        enter_kind
}

const RuntimeContext::new(sched_ptr<u64>, handle_ptr<u64>, driver_ptr<u64>, rng<util.FastRand>, kind<i32>) RuntimeContext {
    c<RuntimeContext> = new RuntimeContext
    c.sched       = sched_ptr
    c.wh_bits     = handle_ptr
    c.drv_bits    = driver_ptr
    c.rng         = rng
    c.coop_budget = 128
    c.enter_kind  = kind
    return c
}

RuntimeContext::drv_handle() DriverHandle {
    if this.drv_bits == 0 return null
    dh<DriverHandle> = null
    dh = this.drv_bits
    return dh
}

mem RtSavedSlot {
    u64 prev_bits
    i64 tid
    i32 slot_idx
}

fn rt_enter(ctx<RuntimeContext>) RtSavedSlot {
    bits<u64> = rtsched.mt_ctx_enter(ctx.(u64))
    return bits.(RtSavedSlot)
}

fn rt_exit(saved<RtSavedSlot>){
    rtsched.mt_ctx_exit(saved.(u64))
}

fn current_context() RuntimeContext {
    bits<u64> = rtsched.mt_ctx_current_bits()
    if bits == 0 return null
    return bits.(RuntimeContext)
}

fn context_driver_handle(rc<RuntimeContext>) DriverHandle {
    if rc == null return null
    return rc.drv_handle()
}

// Build RuntimeContext for an MT worker (mother enter_runtime on the
// worker thread). Scheduler calls this directly — not via fn-ptr bits.
fn mt_worker_ctx_prebuild(sched_bits<u64>, wh_bits<u64>, drv_bits<u64>, rng_bits<u64>) u64 {
    rng<util.FastRand> = null
    if rng_bits != 0 {
        rng = rng_bits.(util.FastRand)
    }
    ctx<RuntimeContext> = RuntimeContext::new(
        sched_bits,
        wh_bits,
        drv_bits,
        rng,
        ENTER_RUNTIME
    )
    return ctx.(u64)
}
