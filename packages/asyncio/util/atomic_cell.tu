// AtomicCell: single-slot atomic container
// Related: packages-asyncio-runtime task 2.4 / 2.5, R19.6
// Design: design §25.2
//
// AtomicCell is the slot used to hand off the core of a multi_thread MtWorker:
// when a worker shuts down it needs to return the core to shutdown_cores, and
// when a different worker steals work it grabs the core via take(). Semantics
// follow Rust crossbeam_utils::atomic::AtomicCell<u64>, but only set / take /
// cas are exposed.

use std.atomic

mem AtomicCell {
    u64 slot
}

// Build an AtomicCell pre-populated with v.
// Construction races never overlap with concurrent access, so a plain assign
// is sufficient.
const AtomicCell::new(v<u64>) AtomicCell {
    return new AtomicCell { slot: v }
}

// set(v): unconditionally store v into the slot.
//   The atomic package does not currently expose xchg64, so we emulate it via a
//   cas64 retry loop. The previous value is discarded.
AtomicCell::set(v<u64>){
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, v) != 0 break
    }
}

// take(): atomically zero the slot and return the original value.
//   Equivalent to std::mem::replace(&cell, 0); used when a worker shuts down
//   and hands its core back.
AtomicCell::take() u64 {
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, 0) != 0 return old
    }
    return 0
}

// cas(old, newv): store newv only if the current value equals old; returns
// true on success, false on failure.
AtomicCell::cas(old<u64>, newv<u64>) bool {
    if atomic.cas64(&this.slot, old, newv) != 0 return true
    return false
}
