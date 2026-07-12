// Globally shared FIFO of Notified tasks (used by both schedulers).
// `len` is atomic so cheap is_empty checks skip the lock; head/tail mutate
// only under `lock`. close() blocks future pushes but pop() still drains.

use runtime
use std.atomic
use io
use asyncio.error as aerr
use asyncio.task

// Atomic depth counter; readers may load it without holding `lock`.
mem InjectShared {
    u32 len
}

// Lock-protected list head/tail and close flag. head/tail hold raw bits of
// RawTask* so &s.head matches task_list_*'s u64* signature.
mem InjectSynced {
    i32 is_closed
    u64 head        // 0 when empty; else raw bits of RawTask*
    u64 tail        // 0 when empty; else raw bits of RawTask*
}

// Public queue handle bundling shared atomic state, lock, and synced fields.
mem Inject {
    InjectShared* shared
    runtime.MutexInter* lock
    InjectSynced* synced
}

// Build an empty, open queue.
const Inject::new() Inject {
    sh<InjectShared> = new InjectShared
    sh.len = 0
    sn<InjectSynced> = new InjectSynced
    sn.is_closed = 0
    sn.head = 0
    sn.tail = 0
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    inj<Inject> = new Inject
    inj.shared = sh
    inj.lock   = m
    inj.synced = sn
    return inj
}

// Snapshot of synced.is_closed; reads under lock to avoid torn updates.
Inject::is_closed() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    closed<i32> = 0
    if s.is_closed == 1 closed = 1
    m.unlock()
    return closed
}

// Lock-free snapshot via atomic len.
Inject::is_empty() i32 {
    sh<InjectShared> = this.shared
    if atomic.load(&sh.len) == 0 return 1
    return 0
}

// Atomic load of the depth counter.
Inject::len() u32 {
    sh<InjectShared> = this.shared
    return atomic.load(&sh.len)
}

// Enqueue at the tail. Returns 0 on success, asyncio.error.Closed when shut.
Inject::push(t<task.Notified>) i32 {
    raw<task.RawTask> = t.raw()
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

// Mark the queue closed; idempotent. Returns 1 only on the first call.
Inject::close() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    first<i32> = 0
    if s.is_closed == 0 {
        s.is_closed = 1
        first = 1
    }
    m.unlock()
    return first
}

// Dequeue the head. Returns (0, Notified) or (io.NotFound, empty) when drained.
Inject::pop() (i32, task.Notified) {
    m<runtime.MutexInter> = this.lock
    m.lock()
    s<InjectSynced> = this.synced
    raw<task.RawTask> = task.task_list_pop_front(&s.head, &s.tail)
    if raw == null {
        m.unlock()
        empty<task.Notified> = task.notified_from_raw(null)
        return io.NotFound, empty
    }
    sh<InjectShared> = this.shared
    atomic.xadd(&sh.len, 0xFFFFFFFF.(u32))
    m.unlock()
    n<task.Notified> = task.notified_from_raw(raw)
    return 0, n
}
