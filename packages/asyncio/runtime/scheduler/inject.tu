// Inject queue: globally-shared FIFO of Notified tasks
// Related: packages-asyncio-runtime task 4.1 / 4.2 / 4.3 / 4.4, R10.1 - R10.9
// Design: design §11
//
// Both current_thread and multi_thread schedulers share this implementation:
// the only structural difference is that multi_thread also exposes a batched
// pop_n_into_local (task 9.15).  Layout:
//   - shared.len    : atomic u32, push/pop adjust it; readers like worker
//                     `is_empty()` may load it without taking the lock
//   - synced.head/tail/is_closed : protected by `lock`
//
// FIFO order is preserved through close() so a shutdown drainer still pulls
// every queued task out in original order before observing the empty state.

use runtime
use std.atomic
use io
use asyncio.error as aerr
use asyncio.task

mem InjectShared {
    u32 len
}

mem InjectSynced {
    i32 is_closed
    head      // RawTask*
    tail      // RawTask*
}

mem Inject {
    shared    // InjectShared*
    lock      // runtime.MutexInter
    synced    // InjectSynced*
}

// new(): build an empty Inject queue.
const Inject::new() Inject {
    sh<InjectShared> = new InjectShared
    sh.len = 0
    sn<InjectSynced> = new InjectSynced
    sn.is_closed = 0
    sn.head = null
    sn.tail = null
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    inj<Inject> = new Inject
    inj.shared = &sh
    inj.lock   = m
    inj.synced = &sn
    return inj
}

// is_closed(): atomic-style snapshot of synced.is_closed.
//   Read under lock to avoid torn updates; cheap because callers only consult
//   it on slow paths.
Inject::is_closed() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    closed<bool> = false
    if s.is_closed == 1 closed = true
    m.unlock()
    return closed
}

// is_empty(): non-locking snapshot via the atomic length counter.
//   May briefly observe `false` when a concurrent push has bumped len before
//   linking the tail; callers must not rely on it for correctness.
Inject::is_empty() bool {
    sh<InjectShared> = this.shared
    if atomic.load(&sh.len) == 0 return true
    return false
}

// len(): current queue depth = total pushes - total pops.
Inject::len() u32 {
    sh<InjectShared> = this.shared
    return atomic.load(&sh.len)
}

// push(t): enqueue Notified `t` at the tail.
//   Returns 0 on success, asyncio.error.Closed when the queue has been
//   marked closed (drainers must be drained before further pushes are
//   rejected).
Inject::push(t) i32 {
    raw = t.raw
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    if s.is_closed == 1 {
        m.unlock()
        return aerr.Closed
    }
    task.task_list_push_back(&s.head, &s.tail, raw)
    sh<InjectShared> = this.shared
    atomic.xadd(&sh.len, 1)
    m.unlock()
    return 0
}

// close(): mark the queue as closed.  Returns true on the first call only.
//   Existing entries remain readable via pop().
Inject::close() bool {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    first<bool> = false
    if s.is_closed == 0 {
        s.is_closed = 1
        first = true
    }
    m.unlock()
    return first
}

// pop(): dequeue the head Notified.
//   Returns (0, Notified) on success or (io.NotFound, Notified{raw:null})
//   when the queue is empty.  Both push and pop are O(1) under the lock.
//   `is_closed` does NOT block pop() — it just blocks future pushes (R10.7).
Inject::pop() (i32, task.Notified) {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    raw = task.task_list_pop_front(&s.head, &s.tail)
    if raw == null {
        m.unlock()
        empty<task.Notified> = task.notified_from_raw(null)
        return io.NotFound, empty
    }
    sh<InjectShared> = this.shared
    atomic.xadd(&sh.len, 0xFFFFFFFF.(u32))   // -1 via two's complement
    m.unlock()
    n<task.Notified> = task.notified_from_raw(raw)
    return 0, n
}
