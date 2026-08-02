// Tracks every Task owned by a scheduler. closed=1 makes bind() reject with
// RuntimeShutdown so shutdown drainers can finish without races.
// Intrusive links live on Header.owned_next/owned_prev — never Header.queue_next
// (that field is exclusive to inject / local Notified queues).

use runtime

// Doubly-linked RawTask list under one mutex.
mem OwnedTasks {
    runtime.MutexInter* lock
    u64 head            // 0 when empty; else raw bits of RawTask*
    u64 tail            // 0 when empty; else raw bits of RawTask*
    i32 closed          // 0/1 monotonic
    i32 active          // live count, mutated under lock
}

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

OwnedTasks::bind(raw<RawTask>) i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    if this.closed == 1 {
        m.unlock()
        return OwnedBindShutdown
    }
    h<Header> = raw.task_header
    h.clear_owned_links()
    t_bits<u64> = this.tail
    if t_bits != 0 {
        prev<RawTask> = t_bits.(RawTask)
        ph<Header> = prev.task_header
        ph.set_owned_next(raw)
        h.set_owned_prev(prev)
    } else {
        this.head = raw.(u64)
    }
    this.tail = raw.(u64)
    this.active += 1
    m.unlock()
    return 0
}

// O(1) unlink via owned_prev / owned_next.
OwnedTasks::remove(rtask<RawTask>){
    m<runtime.MutexInter> = this.lock
    m.lock()
    h<Header> = rtask.task_header
    prv<RawTask> = h.owned_prev_out()
    nxt<RawTask> = h.owned_next_out()
    // Already detached (or never bound): do not clobber head/tail.
    if prv == null && nxt == null && this.head != rtask.(u64) {
        m.unlock()
        return
    }
    if prv != null {
        ph<Header> = prv.task_header
        ph.set_owned_next(nxt)
    } else {
        if nxt == null {
            this.head = 0
        } else {
            this.head = nxt.(u64)
        }
    }
    if nxt != null {
        nh<Header> = nxt.task_header
        nh.set_owned_prev(prv)
    } else {
        if prv == null {
            this.tail = 0
        } else {
            this.tail = prv.(u64)
        }
    }
    h.clear_owned_links()
    if this.active > 0 {
        this.active -= 1
    }
    m.unlock()
}

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

OwnedTasks::is_empty() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    empty<i32> = 0
    if this.head == 0 {
        empty = 1
    }
    m.unlock()
    return empty
}

OwnedTasks::active_count() i32 {
    m<runtime.MutexInter> = this.lock
    m.lock()
    n<i32> = this.active
    m.unlock()
    return n
}
