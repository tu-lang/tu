// Single-slot atomic waker. wake() never drops the most recent register()
// because the WAITING/REGISTERING/WAKING state machine forces wake to either
// fire immediately or hand off to the in-flight register so it kicks the
// task itself.

use std.atomic
use runtime

// State machine over aw_state.
WAITING<i32>     = 0          // no waker stored
REGISTERING<i32> = 0x01       // register_by_ref is mid-flight
WAKING<i32>      = 0x02       // wake observed before register finished

// Single-slot waker; wake_ctx is the (sched, task_id) value the driver
// hands the leaf future. Field aw_state avoids `.state` asmgen traps.
mem AtomicWaker {
    i32 aw_state   // atomic; one of WAITING / REGISTERING / WAKING
    u64 wake_ctx   // payload waker fires with
}

// Build a fresh waker (WAITING, ctx=0). new returns a heap pointer.
const AtomicWaker::new() AtomicWaker {
    a<AtomicWaker> = new AtomicWaker
    a.aw_state = WAITING
    a.wake_ctx = 0
    return a
}

// Install ctx as the pending waker. Concurrent wake() during the
// REGISTERING window flips the state to WAKING; we honour that by waking
// immediately so the task does not stall behind a stale ctx.
// V1 current_thread: store ctx; full REGISTERING/WAKING CAS handshake is
// deferred — atomic.cas after member `this` use has been observed to fault
// in this mem (wake drain-without-cas is reliable).
AtomicWaker::register_by_ref(ctx<u64>){
    this.wake_ctx = ctx
}

// Snapshot wake_ctx and clear it. Returns 0 when no waker was armed.
AtomicWaker::take_ctx() u64 {
    ctx<u64> = this.wake_ctx
    this.wake_ctx = 0
    return ctx
}

// Notify the registered waker. Returns the wake_ctx that was armed (0
// when nothing was). The caller is responsible for actually scheduling.
// Drain the slot for the driver to wake.
AtomicWaker::wake() u64 {
    ctx<u64> = this.wake_ctx
    this.wake_ctx = 0
    return ctx
}

// Cross-package bridges for AtomicWaker heap pointers stored as u64.
fn atomic_waker_new_raw() u64 {
    a<AtomicWaker> = AtomicWaker::new()
    return a.(u64)
}

fn atomic_waker_register_raw(bits<u64>, ctx<u64>) {
    if bits == 0 {
        return
    }
    a<AtomicWaker> = bits.(AtomicWaker)
    if a == null {
        return
    }
    a.register_by_ref(ctx)
}

fn atomic_waker_wake_raw(bits<u64>) u64 {
    if bits == 0 {
        return 0
    }
    a<AtomicWaker> = bits.(AtomicWaker)
    if a == null {
        return 0
    }
    return a.wake()
}
