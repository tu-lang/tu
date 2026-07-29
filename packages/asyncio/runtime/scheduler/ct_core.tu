// Per-loop scratch for the current_thread scheduler. tasks is a ring of
// RawTask raw bits (u64) so the local FIFO matches the steering ban on
// double-pointer types; entries are cast back via slot.(RawTask).

use runtime
use io
use asyncio.task

INITIAL_CAPACITY<u32>             = 64
DEFAULT_GLOBAL_QUEUE_INTERVAL<u32> = 31

// Local ring buffer + tick + driver borrow.
mem Core {
    u64*  ring_slots       // raw bits of RawTask*; sized cap u64 slots
    u32   ring_head
    u32   ring_tail
    u32   ring_cap
    u32   tick
    u64   driver           // raw bits of runtime.driver.Driver*; null = disabled
    u32   global_queue_interval
    i32   unhandled_panic  // 0 = abort on panic (TuLang has no try)
}

// Package-level factory so callers avoid static-call edge cases.
fn ct_core_new(driver_ptr<u64>, global_interval<u32>) Core {
    c<Core> = new Core
    c.ring_cap = INITIAL_CAPACITY
    tc<u32> = c.ring_cap
    cap<u64> = tc.(u64)
    // GC-scanned: slots hold RawTask* bits.
    c.ring_slots     = runtime.malloc(8 * cap, 0.(i8), 1.(i8))
    c.ring_head = 0
    c.ring_tail = 0
    c.tick       = 0
    c.driver     = driver_ptr
    c.global_queue_interval = global_interval
    c.unhandled_panic = 0
    return c
}

// Build an empty core with capacity n. n must be a power of two.
const Core::new(driver_ptr<u64>, global_interval<u32>) Core {
    return ct_core_new(driver_ptr, global_interval)
}

// True when the local ring is non-empty.
Core::has_local() i32 {
    if this.ring_head != this.ring_tail return 1
    return 0
}

// Power-of-two helper: doubles the ring buffer when it's full. Copies
// entries in head-to-tail order so the new ring starts at index 0.
Core::grow(){
    new_cap<u32> = this.ring_cap * 2
    nc<u64> = new_cap.(u64)
    // GC-scanned: slots hold RawTask* bits.
    new_buf<u64*> = runtime.malloc(8 * nc, 0.(i8), 1.(i8))
    n<u32> = (this.ring_tail - this.ring_head)
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (this.ring_head + i) & (this.ring_cap - 1)
        new_buf[i] = this.ring_slots[idx]
    }
    this.ring_slots      = new_buf
    this.ring_head = 0
    this.ring_tail = n
    this.ring_cap  = new_cap
}

// Append t at tail; grows the ring on full.
Core::push_local(t<task.RawTask>){
    if (this.ring_tail - this.ring_head) >= this.ring_cap {
        this.grow()
    }
    idx<u32> = this.ring_tail & (this.ring_cap - 1)
    this.ring_slots[idx] = t.(u64)
    this.ring_tail += 1
}

// Pop head; returns (NotFound, null) when empty.
Core::pop_local() (i32, task.RawTask) {
    if this.ring_head == this.ring_tail {
        return io.NotFound, null
    }
    idx<u32> = this.ring_head & (this.ring_cap - 1)
    bits<u64> = this.ring_slots[idx]
    this.ring_head += 1
    return 0, bits.(task.RawTask)
}

