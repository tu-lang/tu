// Per-thread runtime context. The current_thread / multi_thread schedulers
// (and block_on / spawn_blocking entry points) push a context with
// rt_enter and pop it with rt_exit. current_context() returns null
// outside any runtime, which lets `Handle::current()` surface the
// canonical "no runtime" error code.

use util

// Enter-kind tags so coop / signal can adjust their behaviour.
ENTER_RUNTIME<i32> = 0
ENTER_BLOCK_ON<i32> = 1
ENTER_BLOCKING<i32> = 2

// Active context for the current OS thread; null when nothing is running.
ACTIVE_RT<RuntimeContext> = null

// Combined view used by hot-path helpers (coop, signal handlers).
mem RuntimeContext {
    u64        sched          // raw bits of runtime.scheduler.SchedulerHandle*
    u64        driver         // raw bits of runtime.driver.DriverHandle*
    FastRand*  rng
    i32        coop_budget    // remaining budget in this poll round
    i32        enter_kind     // ENTER_*
}

// Build a context for a given enter point. coop_budget defaults to 128
// (matches DEFAULT_BUDGET in coop.tu but kept duplicated to avoid the
// circular import).
const RuntimeContext::new(sched_ptr<u64>, driver_ptr<u64>, rng<FastRand>, kind<i32>) RuntimeContext {
    c<RuntimeContext> = new RuntimeContext
    c.sched       = sched_ptr
    c.driver      = driver_ptr
    c.rng         = rng
    c.coop_budget = 128
    c.enter_kind  = kind
    return c
}

// Save+swap snapshot. rt_exit takes one back to restore the previous
// (or null) context.
mem RtSavedSlot {
    RuntimeContext* prev
}

// Push ctx as the active context; return the previous slot for restoration.
fn rt_enter(ctx<RuntimeContext>) RtSavedSlot {
    saved<RtSavedSlot> = new RtSavedSlot
    saved.prev = ACTIVE_RT
    ACTIVE_RT  = ctx
    return saved
}

// Restore the previous context; pairs with rt_enter.
fn rt_exit(saved<RtSavedSlot>){
    ACTIVE_RT = saved.prev
}

// Currently active context; null outside a runtime.
fn current_context() RuntimeContext* {
    return ACTIVE_RT
}

