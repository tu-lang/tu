// Per-worker Local FIFO + Steal half-handle. The head word packs steal
// into the upper 32 bits and the real consumer position into the lower
// 32 bits, so steal_into can advance the steal half via CAS while the
// owner pops from the real half independently.
// LOCAL_QUEUE_CAPACITY is fixed at 256.

use std
use std.atomic
use io
use asyncio.task

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS_OK<i64> = 1

// asyncio.error.SendFull
SCHED_SEND_FULL<i32> = 0x0302000A

LOCAL_QUEUE_CAPACITY<u32> = 256
LOCAL_QUEUE_MASK<u32>     = 255

// Combined head field: (steal:u32 << 32) | real:u32.
fn pack_head(steal<u32>, real<u32>) u64 {
    shi<u64> = steal.(u64)
    shi = shi << 32
    rhi<u64> = real.(u64)
    return shi | rhi
}
fn head_steal(h<u64>) u32 {
    hi<u64> = h >> 32
    return hi.(u32)
}
fn head_real(h<u64>) u32 {
    lo<u64> = h & 0xFFFFFFFF
    return lo.(u32)
}

// Wrap-around safe size = tail - head_real (unsigned subtraction).
fn ring_size(tail<u32>, real<u32>) u32 {
    return tail - real
}

// Shared state behind both Local and Steal endpoints.
mem QueueInner {
    u64   head             // atomic; pack_head(steal, real)
    u32   tail             // owner-only; release-stored
    u64*  buffer           // raw bits of RawTask*; LOCAL_QUEUE_CAPACITY u64 slots
}

// Build an empty QueueInner.
const QueueInner::new() QueueInner {
    q<QueueInner> = new QueueInner
    q.head   = 0
    q.tail   = 0
    q.buffer = std.malloc(8 * LOCAL_QUEUE_CAPACITY.(u64))
    return q
}

// Producer side; only the owning worker writes.
mem Local {
    QueueInner* queue_hub
}

// Stealer side; any other worker can drain a slice via steal_into.
mem Steal {
    QueueInner* queue_hub
}

// Build a paired (Steal, Local). The two endpoints share one QueueInner.
// QueueInner::new returns the heap pointer; both endpoints store it raw.
fn queue_local() (Steal, Local) {
    hub<QueueInner> = QueueInner::new()
    s<Steal>          = new Steal { queue_hub: hub }
    l<Local>          = new Local { queue_hub: hub }
    return s, l
}

// Push at tail. Spills half the queue to inject when full so the next
// push always succeeds and stealers can keep up. Returns 0 on success.
Local::push_back_or_overflow(t<task.Notified>, overflow<Inject>) i32 {
    qhub<QueueInner> = this.queue_hub
    raw<task.RawTask> = t.raw()
    raw_bits<u64> = raw.(u64)

    loop {
        h<u64> = atomic.load64(&qhub.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        tail<u32>  = qhub.tail
        size<u32>  = ring_size(tail, steal)

        if size < LOCAL_QUEUE_CAPACITY {
            idx<u32> = tail & LOCAL_QUEUE_MASK
            qhub.buffer[idx] = raw_bits
            qhub.tail = tail + 1
            return 0
        }

        // Queue is full; move half (and the new task) to inject.
        return push_overflow(this, t, overflow)
    }
    return 0
}

// Hand half the queue + the freshly-pushed task to inject. Caller saw a
// full queue; we move LOCAL_QUEUE_CAPACITY/2 entries to inject so the
// remaining slots are immediately writable on the next push.
fn push_overflow(local<Local>, t<task.Notified>, overflow<Inject>) i32 {
    qhub<QueueInner> = local.queue_hub
    n<u32> = LOCAL_QUEUE_CAPACITY / 2

    // Try to claim the first n entries by bumping head.real (and steal
    // back to it afterwards). This races with stealers — if CAS fails we
    // simply retry the outer loop.
    h<u64> = atomic.load64(&qhub.head)
    steal<u32> = head_steal(h)
    real<u32>  = head_real(h)
    if steal != real return SCHED_SEND_FULL   // a stealer is already mid-flight
    new_real<u32> = real + n
    new_h<u64> = pack_head(new_real, new_real)
    if atomic.cas64(&qhub.head, h.(i64), new_h.(i64)) != CAS_OK {
        return SCHED_SEND_FULL
    }

    // Drain the claimed entries to inject in FIFO order.
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (real + i) & LOCAL_QUEUE_MASK
        bits<u64> = qhub.buffer[idx]
        stolen<task.RawTask> = bits.(task.RawTask)
        notif<task.Notified> = task.notified_from_raw(stolen)
        overflow.push(notif)
    }

    // Push the new task into the now-half-empty queue.
    return local.push_back_or_overflow(t, overflow)
}

// Owner pop from head.real. CAS-bumps real on success.
Local::pop() (i32, task.Notified) {
    qhub<QueueInner> = this.queue_hub
    loop {
        h<u64> = atomic.load64(&qhub.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        if real == qhub.tail {
            return io.NotFound, task.notified_from_raw(null)
        }
        idx<u32> = real & LOCAL_QUEUE_MASK
        bits<u64> = qhub.buffer[idx]
        new_h<u64> = pack_head(steal, real + 1)
        if atomic.cas64(&qhub.head, h.(i64), new_h.(i64)) == CAS_OK {
            rt<task.RawTask> = bits.(task.RawTask)
            return 0, task.notified_from_raw(rt)
        }
    }
    return io.NotFound, task.notified_from_raw(null)
}

// Number of queued tasks (best-effort; non-atomic w.r.t. concurrent ops).
Local::len() u32 {
    qhub<QueueInner> = this.queue_hub
    real<u32> = head_real(atomic.load64(&qhub.head))
    return ring_size(qhub.tail, real)
}

// Slots free for push. Stealers being mid-flight count as "still occupied"
// so we mirror the actual write availability.
Local::remaining_slots() u32 {
    qhub<QueueInner> = this.queue_hub
    h<u64> = atomic.load64(&qhub.head)
    steal<u32> = head_steal(h)
    return LOCAL_QUEUE_CAPACITY - ring_size(qhub.tail, steal)
}

// Always 256 — surfaced for tests / metrics.
Local::max_capacity() u32 {
    return LOCAL_QUEUE_CAPACITY
}

// Quick-check from the steal side. Concurrent owner ops may race.
Steal::is_empty() i32 {
    qhub<QueueInner> = this.queue_hub
    h<u64> = atomic.load64(&qhub.head)
    if head_real(h) == qhub.tail return 1
    return 0
}

// Steal up to ceil(size/2) tasks into dst. Returns one of those tasks for
// the caller to run immediately and leaves the rest in dst.
Steal::steal_into(dst<Local>) (i32, task.Notified) {
    src<QueueInner> = this.queue_hub
    dst_inner<QueueInner> = dst.queue_hub

    // Two-phase steal: claim a slice via CAS on head.steal, copy bytes,
    // then commit head.real.
    loop {
        h<u64> = atomic.load64(&src.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        if steal != real {
            return io.NotFound, task.notified_from_raw(null)
        }
        size<u32> = ring_size(src.tail, real)
        if size == 0 {
            return io.NotFound, task.notified_from_raw(null)
        }
        n<u32> = (size + 1) / 2
        new_steal<u32> = real + n
        new_h<u64> = pack_head(new_steal, real)
        if atomic.cas64(&src.head, h.(i64), new_h.(i64)) == CAS_OK {
            // We now own [real, real+n). Copy entries into dst.
            // Limit copy to dst's free capacity.
            avail<u32> = LOCAL_QUEUE_CAPACITY - ring_size(dst_inner.tail, head_real(atomic.load64(&dst_inner.head)))
            if n > avail n = avail

            for i<u32> = 1 ; i < n ; i += 1 {
                src_idx<u32> = (real + i) & LOCAL_QUEUE_MASK
                bits<u64>    = src.buffer[src_idx]
                dst_idx<u32> = (dst_inner.tail + i - 1) & LOCAL_QUEUE_MASK
                dst_inner.buffer[dst_idx] = bits
            }
            dst_inner.tail = dst_inner.tail + n - 1

            // Commit src.head.real, releasing the claimed slice.
            loop {
                h2<u64> = atomic.load64(&src.head)
                new_real2<u32> = real + n
                new_h2<u64> = pack_head(head_steal(h2), new_real2)
                if atomic.cas64(&src.head, h2.(i64), new_h2.(i64)) == CAS_OK break
            }

            // Return the first stolen entry directly to the caller.
            first_idx<u32> = real & LOCAL_QUEUE_MASK
            first_bits<u64> = src.buffer[first_idx]
            first_raw<task.RawTask> = first_bits.(task.RawTask)
            return 0, task.notified_from_raw(first_raw)
        }
    }
    return io.NotFound, task.notified_from_raw(null)
}

