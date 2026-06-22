// Tracks every Task owned by a scheduler. closed=1 makes bind() reject with
// RuntimeShutdown so shutdown drainers can finish without races.
// First-pass uses a single Mutex; sharded variant is future work.

use runtime
use asyncio.error as aerr

// Single-linked list of RawTasks under one mutex; chained via Header.queue_next.
// head/tail hold raw bits of RawTask* so &this.head matches the u64* signature
// of task_list_*; readers cast via bits.(RawTask).
mem OwnedTasks {
    runtime.MutexInter* lock
    u64 head            // 0 when empty; else raw bits of RawTask*
    u64 tail            // 0 when empty; else raw bits of RawTask*
    i32 closed          // 0/1 monotonic
    i32 active          // live count, mutated under lock
}

// Build an empty, open list. MutexInter::new returns the heap pointer
// directly; no `&m`.
const OwnedTasks::new() OwnedTasks {
    o<OwnedTasks> = new OwnedTasks
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    o.lock   = m
    o.head   = 0
    o.tail   = 0
    o.closed = 0
    o.active = 0
    return o
}

// Register raw as owned. Returns 0 on success, RuntimeShutdown when closed
// (closed-path leaves the task unlinked; caller must dealloc).
OwnedTasks::bind(raw<RawTask>) i32 {
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
OwnedTasks::remove(raw<RawTask>){
    m<runtime.MutexInter> = this.lock
    m.lock()
    cur<RawTask> = this.head.(RawTask)
    prev<RawTask> = null
    while cur != null {
        if cur == raw {
            ch<Header> = cur.hdr
            nxt<RawTask> = ch.queue_next
            if prev == null {
                this.head = nxt.(u64)
            } else {
                ph<Header> = prev.hdr
                ph.queue_next = nxt
            }
            if nxt == null this.tail = prev.(u64)
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
    first<bool> = false
    if this.closed == 0 {
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
    if this.head == 0 empty = true
    m.unlock()
    return empty
}

// Live task count; read under lock for consistency.
OwnedTasks::active_count() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    n<i32> = this.active
    m.unlock()
    return n
}

