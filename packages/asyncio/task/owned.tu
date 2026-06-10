// OwnedTasks: tracks every Task owned by a particular scheduler
// Related: packages-asyncio-runtime task 3.25 / 3.26, R8.1, R8.2, R8.3
// Design: design §10.6
//
// Tasks are linked through Header.queue_next (single-linked, intrusive).
// `closed=1` means new bind() calls fail with RuntimeShutdown so shutdown
// drainers can finish without races.
// `active` is the live count of bound RawTasks; updated under lock.
//
// First-pass implementation uses a single Mutex; the design allows sharding
// later for reduced contention.

use runtime
use asyncio.error as aerr

class OwnedTasks {
    lock      // runtime.MutexInter
    head      // Header*
    tail      // Header*
    closed    // i32
    active    // u32
}

OwnedTasks::init(){
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    this.lock   = m
    this.head   = null
    this.tail   = null
    this.closed = 0
    this.active = 0
}

// bind(raw): register `raw` as owned.
//   Returns 0 on success, asyncio.error.RuntimeShutdown when closed.
//   On the closed path the task is NOT linked, the caller must dealloc.
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

// remove(raw): unlink `raw`.  Caller must guarantee `raw` is in this list.
//   Implementation walks the singly-linked list O(n) since OwnedTasks does
//   not store back pointers; design notes mark this as acceptable for the
//   first-pass impl (sharded variant comes later).
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

// close(): mark this set as closed so further bind() calls fail.
//   Returns true on the first call, false on every subsequent call.
OwnedTasks::close() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    if this.closed == 1 {
        m.unlock()
        return false
    }
    this.closed = 1
    m.unlock()
    return true
}

// is_empty(): no tasks currently linked.  Atomic snapshot under lock.
OwnedTasks::is_empty() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    empty<bool> = false
    if this.head == null empty = true
    m.unlock()
    return empty
}

// active_count(): expose the live counter.  Read under lock for consistency.
OwnedTasks::active_count() u32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    n<u32> = this.active
    m.unlock()
    return n
}
