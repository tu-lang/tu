// Per-worker Local FIFO + Steal half-handle. The head word packs steal
// into the upper 32 bits and the real consumer position into the lower
// 32 bits, so steal_into can advance the steal half via CAS while the
// owner pops from the real half independently.
// LOCAL_QUEUE_CAPACITY=256 matches tokio.

use std
use std.atomic
use io
use asyncio.task
use asyncio.error as aerr

LOCAL_QUEUE_CAPACITY<u32> = 256
LOCAL_QUEUE_MASK<u32>     = 255

// Combined head field: (steal:u32 << 32) | real:u32.
fn pack_head(steal<u32>, real<u32>) u64 {
    return (steal.(u64) << 32) | real.(u64)
}
fn head_steal(h<u64>) u32 {
    return (h >> 32).(u32)
}
fn head_real(h<u64>) u32 {
    return (h & 0xFFFFFFFF).(u32)
}

// Wrap-around safe size = tail - head_real (unsigned subtraction).
fn ring_size(tail<u32>, real<u32>) u32 {
    return (tail - real).(u32) & 0xFFFFFFFF
}

// Shared state behind both Local and Steal endpoints.
mem QueueInner {
    u64   head             // atomic; pack_head(steal, real)
    u32   tail             // owner-only; release-stored
    u64*  buffer           // raw bits of RawTask*; LOCAL_QUEUE_CAPACITY u64 slots
}

// Build an empty QueueInner.
const QueueInner::new() QueueInner* {
    q<QueueInner> = new QueueInner
    q.head   = 0
    q.tail   = 0
    q.buffer = std.malloc(sizeof(u64) * LOCAL_QUEUE_CAPACITY.(u64))
    return &q
}

// Producer side; only the owning worker writes.
mem Local {
    QueueInner* inner
}

// Stealer side; any other worker can drain a slice via steal_into.
mem Steal {
    QueueInner* inner
}

// Build a paired (Steal, Local). The two endpoints share one QueueInner.
const queue_local() (Steal, Local) {
    inner<QueueInner> = QueueInner::new()
    s<Steal>          = new Steal { inner: &inner }
    l<Local>          = new Local { inner: &inner }
    return s, l
}

// Push at tail. Spills half the queue to inject when full so the next
// push always succeeds and stealers can keep up. Returns 0 on success.
Local::push_back_or_overflow(t<task.Notified>, overflow<Inject>) i32 {
    inner<QueueInner> = this.inner
    raw_bits<u64> = t.raw.(u64)

    loop {
        h<u64> = atomic.load64(&inner.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        tail<u32>  = inner.tail
        size<u32>  = ring_size(tail, steal)

        if size < LOCAL_QUEUE_CAPACITY {
            idx<u32> = tail & LOCAL_QUEUE_MASK
            inner.buffer[idx] = raw_bits
            // Release-store new tail; readers see the write before tail.
            atomic.store32(&inner.tail.(i32*), inner.tail.(i32), (tail + 1).(i32))
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
    inner<QueueInner> = local.inner
    n<u32> = LOCAL_QUEUE_CAPACITY / 2

    // Try to claim the first n entries by bumping head.real (and steal
    // back to it afterwards). This races with stealers — if CAS fails we
    // simply retry the outer loop.
    h<u64> = atomic.load64(&inner.head)
    steal<u32> = head_steal(h)
    real<u32>  = head_real(h)
    if steal != real return aerr.SendFull   // a stealer is already mid-flight
    new_real<u32> = real + n
    new_h<u64> = pack_head(new_real, new_real)
    if atomic.cas64(&inner.head.(i64*), h.(i64), new_h.(i64)) == 0 {
        return aerr.SendFull
    }

    // Drain the claimed entries to inject in FIFO order.
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (real + i) & LOCAL_QUEUE_MASK
        bits<u64> = inner.buffer[idx]
        notif<task.Notified> = task.notified_from_raw(bits.(task.RawTask))
        overflow.push(notif)
    }

    // Push the new task into the now-half-empty queue.
    return local.push_back_or_overflow(t, overflow)
}

// Owner pop from head.real. CAS-bumps real on success.
Local::pop() (i32, task.Notified) {
    inner<QueueInner> = this.inner
    loop {
        h<u64> = atomic.load64(&inner.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        if real == inner.tail {
            return io.NotFound, task.notified_from_raw(null)
        }
        idx<u32> = real & LOCAL_QUEUE_MASK
        bits<u64> = inner.buffer[idx]
        new_h<u64> = pack_head(steal, real + 1)
        if atomic.cas64(&inner.head.(i64*), h.(i64), new_h.(i64)) != 0 {
            return 0, task.notified_from_raw(bits.(task.RawTask))
        }
    }
    return io.NotFound, task.notified_from_raw(null)
}

// Number of queued tasks (best-effort; non-atomic w.r.t. concurrent ops).
Local::len() u32 {
    inner<QueueInner> = this.inner
    real<u32> = head_real(atomic.load64(&inner.head))
    return ring_size(inner.tail, real)
}

// Slots free for push. Stealers being mid-flight count as "still occupied"
// so we mirror the actual write availability.
Local::remaining_slots() u32 {
    inner<QueueInner> = this.inner
    h<u64> = atomic.load64(&inner.head)
    steal<u32> = head_steal(h)
    return LOCAL_QUEUE_CAPACITY - ring_size(inner.tail, steal)
}

// Always 256 — surfaced for tests / metrics.
Local::max_capacity() u32 {
    return LOCAL_QUEUE_CAPACITY
}

// Quick-check from the steal side. Concurrent owner ops may race.
Steal::is_empty() bool {
    inner<QueueInner> = this.inner
    h<u64> = atomic.load64(&inner.head)
    if head_real(h) == inner.tail return true
    return false
}

// Steal up to ceil(size/2) tasks into dst. Returns one of those tasks for
// the caller to run immediately and leaves the rest in dst.
Steal::steal_into(dst<Local>) (i32, task.Notified) {
    src<QueueInner> = this.inner
    dst_inner<QueueInner> = dst.inner

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
        if atomic.cas64(&src.head.(i64*), h.(i64), new_h.(i64)) != 0 {
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
            // Publish dst's new tail.
            atomic.store32(&dst_inner.tail.(i32*), dst_inner.tail.(i32), (dst_inner.tail + n - 1).(i32))

            // Commit src.head.real, releasing the claimed slice.
            loop {
                h2<u64> = atomic.load64(&src.head)
                new_real2<u32> = real + n
                new_h2<u64> = pack_head(head_steal(h2), new_real2)
                // The stealer hasn't done anything else, so we expect
                // head_steal(h2) == real + n. CAS may fail only if the
                // owner pop'd in the meantime, in which case head_real
                // has advanced past `real`.
                if atomic.cas64(&src.head.(i64*), h2.(i64), new_h2.(i64)) != 0 break
            }

            // Return the first stolen entry directly to the caller.
            first_idx<u32> = real & LOCAL_QUEUE_MASK
            first_bits<u64> = src.buffer[first_idx]
            return 0, task.notified_from_raw(first_bits.(task.RawTask))
        }
    }
    return io.NotFound, task.notified_from_raw(null)
}

