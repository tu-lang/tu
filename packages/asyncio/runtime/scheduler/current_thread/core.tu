// Per-loop scratch for the current_thread scheduler. tasks is a ring of
// RawTask raw bits (u64) so the local FIFO matches the steering ban on
// double-pointer types; entries are cast back via slot.(RawTask).

use std

INITIAL_CAPACITY<u32>             = 64
DEFAULT_GLOBAL_QUEUE_INTERVAL<u32> = 31

// Local ring buffer + tick + driver borrow.
mem Core {
    u64*  tasks            // raw bits of RawTask*; sized cap u64 slots
    u32   tasks_head
    u32   tasks_tail
    u32   tasks_cap
    u32   tick
    u64   driver           // raw bits of runtime.driver.Driver*; null = disabled
    u32   global_queue_interval
    i32   unhandled_panic  // 0 = abort on panic (TuLang has no try)
}

// Build an empty core with capacity n. n must be a power of two.
const Core::new(driver_ptr<u64>, global_interval<u32>) Core* {
    c<Core> = new Core
    c.tasks_cap = INITIAL_CAPACITY
    c.tasks     = std.malloc(sizeof(u64) * c.tasks_cap.(u64))
    c.tasks_head = 0
    c.tasks_tail = 0
    c.tick       = 0
    c.driver     = driver_ptr
    c.global_queue_interval = global_interval
    c.unhandled_panic = 0
    return &c
}

// True when the local ring is non-empty.
Core::has_local() bool {
    if this.tasks_head != this.tasks_tail return true
    return false
}

// Power-of-two helper: doubles the ring buffer when it's full. Copies
// entries in head-to-tail order so the new ring starts at index 0.
Core::grow(){
    new_cap<u32> = this.tasks_cap * 2
    new_buf<u64*> = std.malloc(sizeof(u64) * new_cap.(u64))
    n<u32> = (this.tasks_tail - this.tasks_head)
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (this.tasks_head + i) & (this.tasks_cap - 1)
        new_buf[i] = this.tasks[idx]
    }
    this.tasks      = new_buf
    this.tasks_head = 0
    this.tasks_tail = n
    this.tasks_cap  = new_cap
}

// Append t at tail; grows the ring on full.
Core::push_local(t<task.RawTask>){
    if (this.tasks_tail - this.tasks_head) >= this.tasks_cap {
        this.grow()
    }
    idx<u32> = this.tasks_tail & (this.tasks_cap - 1)
    this.tasks[idx] = t.(u64)
    this.tasks_tail += 1
}

// Pop head; returns (NotFound, null) when empty.
Core::pop_local() (i32, task.RawTask*) {
    if this.tasks_head == this.tasks_tail {
        return io.NotFound, null
    }
    idx<u32> = this.tasks_head & (this.tasks_cap - 1)
    bits<u64> = this.tasks[idx]
    this.tasks_head += 1
    return 0, bits.(task.RawTask)
}

