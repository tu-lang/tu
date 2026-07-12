// Tracks every Task owned by a scheduler. closed=1 makes bind() reject with
// RuntimeShutdown so shutdown drainers can finish without races.
// First-pass uses a single Mutex; sharded variant is future work.

use runtime

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
        return OwnedBindShutdown
    }
    task_list_push_back(&this.head, &this.tail, raw)
    this.active += 1
    m.unlock()
    return 0
}

// Unlink raw. O(n) walk because the list has no back pointers (acceptable
// for the first-pass impl). Caller must guarantee raw lives on this list.
OwnedTasks::remove(rtask<RawTask>){
    m<runtime.MutexInter> = this.lock
    m.lock()
    cur_bits<u64> = this.head
    prev_bits<u64> = 0
    while cur_bits != 0 {
        cur<RawTask> = cur_bits.(RawTask)
        if cur == rtask {
            nxt<RawTask> = cur.list_take_next()
            if prev_bits == 0 {
                if nxt == null this.head = 0
                else this.head = nxt.(u64)
            } else {
                prev<RawTask> = prev_bits.(RawTask)
                prev.list_link_next(nxt)
            }
            if nxt == null {
                this.tail = prev_bits
            }
            cur.list_prep_push()
            this.active -= 1
            break
        }
        prev_bits = cur_bits
        nxt<RawTask> = cur.list_take_next()
        if nxt == null {
            cur_bits = 0
        } else {
            cur_bits = nxt.(u64)
        }
    }
    m.unlock()
}

// Mark closed. Idempotent — returns 1 only on the first call.
OwnedTasks::close() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    first<i32> = 0
    if this.closed == 0 {
        this.closed = 1
        first = 1
    }
    m.unlock()
    return first
}

// Atomic-ish snapshot: read head under lock to avoid torn updates.
OwnedTasks::is_empty() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    empty<i32> = 0
    if this.head == 0 empty = 1
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
