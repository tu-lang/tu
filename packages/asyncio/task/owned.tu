// Tracks every Task owned by a scheduler. closed=1 makes bind() reject with
// RuntimeShutdown so shutdown drainers can finish without races.
// First-pass uses a single Mutex; sharded variant is future work.

use runtime
use asyncio.error as aerr

// Single-linked list of Headers under one mutex.
class OwnedTasks {
    lock      // runtime.MutexInter
    head      // Header*, null when empty
    tail      // Header*, null when empty
    closed    // i32 0/1
    active    // u32 live count, mutated under lock
}

// Initialise to an empty, open list.
OwnedTasks::init(){
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    this.lock   = m
    this.head   = null
    this.tail   = null
    this.closed = 0
    this.active = 0
}

// Register raw as owned. Returns 0 on success, RuntimeShutdown when closed
// (closed-path leaves the task unlinked; caller must dealloc).
OwnedTasks::bind(raw) i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    if this.closed == 1 {
        m.unlock()
        return aerr.RuntimeShutdown
    }
    task_list_push_back(&this.head, &this.tail, raw)
    this.active += 1
    m.unlock()
    return 0
}

// Unlink raw. O(n) walk because the list has no back pointers (acceptable
// for the first-pass impl). Caller must guarantee raw lives on this list.
OwnedTasks::remove(raw){
    m<runtime.MutexInter> = this.lock
    m.lock()
    h<Header> = raw.hdr
    cur = this.head
    prev = null
    while cur != null {
        if cur == raw {
            ch<Header> = cur.hdr
            nxt = ch.queue_next
            if prev == null {
                this.head = nxt
            } else {
                ph<Header> = prev.hdr
                ph.queue_next = nxt
            }
            if nxt == null this.tail = prev
            ch.queue_next = null
            this.active -= 1
            break
        }
        prev = cur
        ch<Header> = cur.hdr
        cur = ch.queue_next
    }
    m.unlock()
}

// Mark closed. Idempotent — returns true only on the first call.
OwnedTasks::close() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<i32> = this.closed
    first<bool> = false
    if s == 0 {
        this.closed = 1
        first = true
    }
    m.unlock()
    return first
}

// Atomic-ish snapshot: read head under lock to avoid torn updates.
OwnedTasks::is_empty() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    empty<bool> = false
    if this.head == null empty = true
    m.unlock()
    return empty
}

// Live task count; read under lock for consistency.
OwnedTasks::active_count() u32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    n<u32> = this.active
    m.unlock()
    return n
}
