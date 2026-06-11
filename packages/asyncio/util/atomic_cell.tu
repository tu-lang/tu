// Single-slot u64 atomic container; used to hand off a worker's core slot.

use std.atomic

// Atomic u64 storage; semantics align with crossbeam's AtomicCell<u64>.
mem AtomicCell {
    u64 slot
}

// Construct a cell pre-populated with v (caller is the sole owner here).
const AtomicCell::new(v<u64>) AtomicCell {
    return new AtomicCell { slot: v }
}

// Unconditionally store v. Emulates xchg64 via a cas64 retry loop.
AtomicCell::set(v<u64>){
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, v) != 0 break
    }
}

// Atomically swap to 0 and return the previous value.
AtomicCell::take() u64 {
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, 0) != 0 return old
    }
    return 0
}

// Compare-and-swap. Returns true on success.
AtomicCell::cas(old<u64>, newv<u64>) bool {
    if atomic.cas64(&this.slot, old, newv) != 0 return true
    return false
}
