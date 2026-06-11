// Defer: thread-local pending list for tasks woken inside a polling round
// Related: packages-asyncio-runtime task 4.7, R11.1 - R11.4
// Design: design §11
//
// Wakers that fire while the harness is mid-poll cannot push directly into
// the run queue (the worker is currently holding it).  Defer collects those
// RawTasks into a small array; once the polling round ends, the worker
// drains Defer into the inject queue before checking remote work.
//
// Single-threaded by construction: it lives inside one worker's frame.

use std

mem Defer {
    cap     // i32, current capacity of the slots array
    len     // i32, occupied slots
    slots   // RawTask** (modeled as dynamic array)
}

const Defer::new() Defer {
    d<Defer> = new Defer
    d.cap = 16
    d.len = 0
    d.slots = []
    return d
}

// is_empty(): no tasks pending
Defer::is_empty() bool {
    if this.len == 0 return true
    return false
}

// push(raw): append a RawTask waiting to run after the current poll round.
//   The slots array grows dynamically; when capacity is hit we rely on the
//   underlying array's append-with-grow semantics (a[] = x).
Defer::push(raw){
    arr = this.slots
    arr[] = raw
    this.slots = arr
    this.len += 1
}

// drain_into_inject(inj): move every queued task into the inject queue and
// reset Defer.  Called after the worker finishes a polling round.
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

// wake_by_ref(): drop everything without scheduling.
//   Used in the rare paths where the worker has just observed it should
//   shut down; the caller has already chained the proper teardown.
Defer::wake_by_ref(){
    this.slots = []
    this.len = 0
}
