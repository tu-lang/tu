// Single-slot atomic waker. wake() never drops the most recent register()
// because the WAITING/REGISTERING/WAKING state machine forces wake to either
// fire immediately or hand off to the in-flight register so it kicks the
// task itself.

use std.atomic
use runtime

// State machine over `state`.
WAITING<i32>     = 0          // no waker stored
REGISTERING<i32> = 0b01       // register_by_ref is mid-flight
WAKING<i32>      = 0b10       // wake observed before register finished

// Single-slot waker; ctx_packed is the (sched, task_id) value the driver
// hands the leaf future.
mem AtomicWaker {
    i32 state         // atomic; one of the constants above
    u64 ctx_packed    // payload waker fires with
}

// Build an empty waker (state=WAITING, ctx=0).
const AtomicWaker::new() AtomicWaker* {
    a<AtomicWaker> = new AtomicWaker
    a.state       = WAITING
    a.ctx_packed  = 0
    return &a
}

// Install ctx as the pending waker. Concurrent wake() during the
// REGISTERING window flips the state to WAKING; we honour that by waking
// immediately so the task does not stall behind a stale ctx.
AtomicWaker::register_by_ref(ctx<u64>){
    addr<i32*> = &this.state

    // Try the fast path: WAITING -> REGISTERING. If that fails, either
    // another register is in flight or wake() raced ahead — fall back to
    // wiring ctx and notifying directly.
    if atomic.cas(addr, WAITING, REGISTERING) == 0 {
        cur<i32> = *addr
        if cur == REGISTERING return
        if cur == WAKING {
            // wake() landed first; deliver this ctx ourselves so the task
            // is reschedulable immediately.
            this.ctx_packed = ctx
            atomic.cas(addr, WAKING, WAITING)
            return
        }
        return
    }

    this.ctx_packed = ctx

    // Drop back to WAITING. If wake() flipped us to WAKING during the
    // assignment we honour it by clearing the slot here (the task is
    // already on its way to the run queue from the wake side).
    if atomic.cas(addr, REGISTERING, WAITING) != 0 return
    cur<i32> = *addr
    if cur == WAKING {
        atomic.cas(addr, WAKING, WAITING)
    }
}

// Snapshot ctx_packed and clear it. Returns 0 when no waker was armed.
AtomicWaker::take_ctx() u64 {
    ctx<u64> = this.ctx_packed
    this.ctx_packed = 0
    return ctx
}

// Notify the registered waker. Returns the ctx_packed that was armed (0
// when nothing was). The caller is responsible for actually scheduling.
// Concurrent register_by_ref observes WAKING and re-arms itself.
AtomicWaker::wake() u64 {
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        if cur == WAKING return 0
        if cur == REGISTERING {
            // Hand the kick to the registering thread; it sees WAKING and
            // schedules the freshly stored ctx itself.
            if atomic.cas(addr, REGISTERING, WAKING) != 0 return 0
            continue
        }
        // cur == WAITING: claim the slot, drain ctx, return it to caller.
        if atomic.cas(addr, WAITING, WAKING) != 0 {
            ctx<u64> = this.ctx_packed
            this.ctx_packed = 0
            atomic.cas(addr, WAKING, WAITING)
            return ctx
        }
    }
    return 0
}

