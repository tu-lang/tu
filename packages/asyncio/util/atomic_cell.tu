// Single-slot u64 atomic container; used to hand off a worker's core slot.

use std.atomic

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS64_OK<i64> = 1

// Atomic u64 storage; semantics align with crossbeam's AtomicCell<u64>.
mem AtomicCell {
    u64 slot
}

// Construct a cell pre-populated with v (caller is the sole owner here).
const AtomicCell::new(v<u64>) AtomicCell {
    return new AtomicCell { slot: v }
}

// Package-level bridge for cross-package callers (no alias.Type::method).
fn atomic_cell_new(v<u64>) AtomicCell {
    return AtomicCell::new(v)
}

// Unconditionally store v. Emulates xchg64 via a cas64 retry loop.
AtomicCell::set(v<u64>){
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, v) == CAS64_OK break
    }
}

// Atomically swap to 0 and return the previous value.
AtomicCell::take() u64 {
    loop {
        old<u64> = atomic.load64(&this.slot)
        if atomic.cas64(&this.slot, old, 0) == CAS64_OK return old
    }
    return 0
}

// Compare-and-swap. Returns true on success.
AtomicCell::cas(old<u64>, nxt<u64>) i32 {
    if atomic.cas64(&this.slot, old, nxt) == CAS64_OK return 1
    return 0
}
