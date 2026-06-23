// Per-worker scratch list. Wakers fired during a polling round park their
// RawTasks here; the worker drains into inject after the round finishes.
// Single-threaded by construction.

use std
use asyncio.task

INITIAL_CAP<i32> = 16

// Slot array holds raw bits of RawTask*; readers cast via slot.(RawTask).
mem Defer {
    i32 cap         // current allocated capacity
    i32 len         // occupied slots
    u64* slots      // null until first grow; sized cap*sizeof(u64)
}

// Build an empty Defer; first push grows to INITIAL_CAP.
const Defer::new() Defer {
    d<Defer> = new Defer
    d.cap = 0
    d.len = 0
    d.slots = null
    return d
}

Defer::is_empty() bool {
    if this.len == 0 return true
    return false
}

// Grow slots to max(INITIAL_CAP, cap*2) and copy existing entries over.
Defer::grow(){
    new_cap<i32> = INITIAL_CAP
    if this.cap > 0 {
        new_cap = this.cap * 2
    }
    new_slots<u64*> = std.malloc(sizeof(u64) * new_cap.(u64))
    n<i32> = this.len
    if n > 0 {
        old<u64*> = this.slots
        for i<i32> = 0 ; i < n ; i += 1 {
            new_slots[i] = old[i]
        }
    }
    this.slots = new_slots
    this.cap   = new_cap
}

// Append raw to the pending list. Grows the backing array on demand.
Defer::push(raw<task.RawTask>){
    if this.len == this.cap {
        this.grow()
    }
    this.slots[this.len] = raw.(u64)
    this.len += 1
}

// Move every queued task into inject and reset the list.
Defer::drain_into_inject(inj<Inject>){
    n<i32> = this.len
    arr<u64*> = this.slots
    for i<i32> = 0 ; i < n ; i += 1 {
        bits<u64> = arr[i]
        raw<task.RawTask> = bits.(task.RawTask)
        notif<task.Notified> = task.notified_from_raw(raw)
        inj.push(notif)
    }
    this.len = 0
}

// Drop everything without scheduling; only used on the teardown path.
Defer::wake_by_ref(){
    this.len = 0
}

