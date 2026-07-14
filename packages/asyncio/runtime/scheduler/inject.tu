// Globally shared FIFO of Notified tasks (used by both schedulers).
// `len` is atomic so cheap is_empty checks skip the lock; head/tail mutate
// only under `lock`. close() blocks future pushes but pop() still drains.

use runtime
use std.atomic
use io
use asyncio.task

// asyncio.error.Closed (0x03020002); local alias — scheduler cannot pull
// parent package consts via `aerr.Closed` in this package.
INJECT_CLOSED<i32> = 0x03020002

// Atomic depth counter; readers may load it without holding `lock`.
mem InjectShared {
    u32 depth
}

// Lock-protected list head/tail and close flag. head/tail hold raw bits of
// RawTask* so &s.head matches task_list_*'s u64* signature.
mem InjectSynced {
    i32 shut_flag
    u64 head        // 0 when empty; else raw bits of RawTask*
    u64 tail        // 0 when empty; else raw bits of RawTask*
}

// Public queue handle bundling shared atomic state, lock, and fifo fields.
mem Inject {
    InjectShared* depth_atomic
    runtime.MutexInter* gate_lock
    InjectSynced* fifo_state
}

// Build an empty, open queue.
const Inject::new() Inject {
    sh<InjectShared> = new InjectShared
    sh.depth = 0
    sn<InjectSynced> = new InjectSynced
    sn.shut_flag = 0
    sn.head = 0
    sn.tail = 0
    m<runtime.MutexInter> = new runtime.MutexInter
    m.init()
    inj<Inject> = new Inject
    inj.depth_atomic = sh
    inj.gate_lock   = m
    inj.fifo_state = sn
    return inj
}

// Snapshot of fifo shut_flag; reads under lock to avoid torn updates.
Inject::is_closed() i32 {
    m<runtime.MutexInter> = this.gate_lock
    m.lock()
    s<InjectSynced> = this.fifo_state
    closed<i32> = 0
    if s.shut_flag == 1 closed = 1
    m.unlock()
    return closed
}

// Lock-free snapshot via atomic len.
Inject::is_empty() i32 {
    sh<InjectShared> = this.depth_atomic
    if atomic.load(&sh.depth) == 0 return 1
    return 0
}

// Atomic load of the depth counter.
Inject::len() u32 {
    sh<InjectShared> = this.depth_atomic
    return atomic.load(&sh.depth)
}

// Enqueue at the tail. Returns 0 on success, asyncio.error.Closed when shut.
Inject::push(t<task.Notified>) i32 {
    raw<task.RawTask> = t.raw()
    m<runtime.MutexInter> = this.gate_lock
    m.lock()
    s<InjectSynced> = this.fifo_state
    if s.shut_flag == 1 {
        m.unlock()
        return INJECT_CLOSED
    }
    task.task_list_push_back(&s.head, &s.tail, raw)
    sh<InjectShared> = this.depth_atomic
    atomic.xadd(&sh.depth, 1)
    m.unlock()
    return 0
}

// Mark the queue closed; idempotent. Returns 1 only on the first call.
Inject::close() i32 {
    m<runtime.MutexInter> = this.gate_lock
    m.lock()
    s<InjectSynced> = this.fifo_state
    first<i32> = 0
    if s.shut_flag == 0 {
        s.shut_flag = 1
        first = 1
    }
    m.unlock()
    return first
}

// Dequeue the head. Returns (0, Notified) or (io.NotFound, empty) when drained.
Inject::pop() (i32, task.Notified) {
    m<runtime.MutexInter> = this.gate_lock
    m.lock()
    s<InjectSynced> = this.fifo_state
    raw<task.RawTask> = task.task_list_pop_front(&s.head, &s.tail)
    if raw == null {
        m.unlock()
        empty<task.Notified> = task.notified_from_raw(null)
        return io.NotFound, empty
    }
    sh<InjectShared> = this.depth_atomic
    atomic.xadd(&sh.depth, 0xFFFFFFFF.(u32))
    m.unlock()
    n<task.Notified> = task.notified_from_raw(raw)
    return 0, n
}
