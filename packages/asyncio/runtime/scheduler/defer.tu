// Per-worker scratch list. Wakers fired during a polling round park their
// RawTasks here; the worker drains into inject after the round finishes.
// Single-threaded by construction.

use std

// Dynamic array of RawTask* pending re-schedule.
mem Defer {
    cap     // i32 current capacity
    len     // i32 occupied slots
    slots   // dynamic array of RawTask*
}

// Build an empty Defer with initial capacity.
const Defer::new() Defer {
    d<Defer> = new Defer
    d.cap = 16
    d.len = 0
    d.slots = []
    return d
}

Defer::is_empty() bool {
    if this.len == 0 return true
    return false
}

// Append raw to the pending list. The underlying dynamic array grows as needed.
Defer::push(raw){
    arr = this.slots
    arr[] = raw
    this.slots = arr
    this.len += 1
}

// Move every queued task into inject and reset.
Defer::drain_into_inject(inj){
    arr = this.slots
    n<i32> = this.len
    for i<i32> = 0 ; i < n ; i += 1 {
        raw = arr[i]
        notif = asyncio.task.notified_from_raw(raw)
        inj.push(notif)
    }
    this.slots = []
    this.len = 0
}

// Drop everything without scheduling; only used on the teardown path.
Defer::wake_by_ref(){
    this.slots = []
    this.len = 0
}
