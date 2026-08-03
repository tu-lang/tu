// Per-worker Local FIFO + Steal half-handle. The head word packs steal
// into the upper 32 bits and the real consumer position into the lower
// 32 bits, so steal_into can advance the steal half via CAS while the
// owner pops from the real half independently.
// LOCAL_QUEUE_CAPACITY is fixed at 256.

use std.atomic
use runtime
use io
use asyncio.task

// CAS success sentinels. i32 atomic.cas and i64 cas64 both return 1 on
// success; keep typed constants (bare 0/1 literals break binary-op).
// Do not compare i32 cas against CAS64_OK — use CAS_OK for i32.
CAS_OK<i32>   = 1
CAS64_OK<i64> = 1

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

// Atomically take one buffer slot (swap to 0). Plain load+store races let
// owner pop and stealer both observe the same RawTask* under GC pressure.
// Avoid &buf[idx] (compiler trap); advance a u64* by byte offset instead.
fn buffer_take(buf<u64*>, idx<u32>) u64 {
    addr<u64*> = buf
    byte_off<u64> = idx.(u64) << 3
    addr += byte_off
    loop {
        bits<u64> = atomic.load64(addr)
        if bits == 0 {
            return 0
        }
        if atomic.cas64(addr, bits.(i64), 0.(i64)) == CAS64_OK {
            return bits
        }
    }
    return 0
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
    // Default scannable allocation: occupied slots are strong RawTask* roots.
    // Every dequeue path (pop / steal / overflow) must zero the slot before the
    // task can be freed — do not pass noscan to paper over stale bits.
    q.buffer = runtime.malloc(8 * LOCAL_QUEUE_CAPACITY.(u64), 0.(i8), 1.(i8))
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
// Mother queue.rs Local::push_back: capacity uses steal; if full while a
// stealer is mid-flight (steal != real), push to inject — never drop.
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

        // Full + concurrent steal: stealer will free capacity; park task
        // on inject (mother). Returning SCHED_SEND_FULL here dropped tasks
        // and left workers parked with no runnable work under MT spawn load.
        if steal != real {
            overflow.push(t)
            return 0
        }

        // Full, no stealer: move half + the new task to inject.
        if push_overflow(this, t, overflow, real, tail) == 0 {
            return 0
        }
        // CAS lost the race — retry with the same task.
    }
    return 0
}

// Claim half the local queue and push those entries plus `t` onto inject.
// Returns 0 on success, 1 if CAS lost (caller retries). Mother push_overflow.
fn push_overflow(local<Local>, t<task.Notified>, overflow<Inject>, real<u32>, tail<u32>) i32 {
    qhub<QueueInner> = local.queue_hub
    n<u32> = LOCAL_QUEUE_CAPACITY / 2

    prev<u64> = pack_head(real, real)
    new_real<u32> = real + n
    new_h<u64> = pack_head(new_real, new_real)
    if atomic.cas64(&qhub.head, prev.(i64), new_h.(i64)) != CAS64_OK {
        return 1
    }

    // Drain the claimed entries to inject in FIFO order, then the new task
    // (mother push_batch(batch.chain(once(task)))).
    for i<u32> = 0 ; i < n ; i += 1 {
        idx<u32> = (real + i) & LOCAL_QUEUE_MASK
        bits<u64> = buffer_take(qhub.buffer, idx)
        if bits == 0 {
            continue
        }
        stolen<task.RawTask> = bits.(task.RawTask)
        notif<task.Notified> = task.notified_from_raw(stolen)
        overflow.push(notif)
    }
    overflow.push(t)
    return 0
}

// Owner pop from head.real. CAS-bumps real on success.
// When no stealer is mid-flight (steal == real), advance both halves —
// mother queue.rs Local::pop. Leaving steal behind permanently blocks
// steal_into / overflow (steal != real) and desyncs capacity vs real depth.
Local::pop() (i32, task.Notified) {
    qhub<QueueInner> = this.queue_hub
    loop {
        h<u64> = atomic.load64(&qhub.head)
        steal<u32> = head_steal(h)
        real<u32>  = head_real(h)
        if real == qhub.tail {
            return io.NotFound, task.notified_from_raw(null)
        }
        next_real<u32> = real + 1
        new_h<u64> = 0
        if steal == real {
            new_h = pack_head(next_real, next_real)
        } else {
            new_h = pack_head(steal, next_real)
        }
        if atomic.cas64(&qhub.head, h.(i64), new_h.(i64)) == CAS64_OK {
            idx<u32> = real & LOCAL_QUEUE_MASK
            // Atomic take: clear before the task can complete/free so the
            // scannable buffer never retains a pointer after dequeue.
            bits<u64> = buffer_take(qhub.buffer, idx)
            if bits == 0 {
                // Slot already drained (should be rare with correct claim).
                continue
            }
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

// Steal up to ceil(size/2) tasks into dst. Returns one stolen task for the
// caller and leaves the rest in dst.
//
// Mother (queue.rs steal_into2):
// 1) Claim by advancing head.real (keep head.steal) so steal != real blocks
//    other stealers; owner Local::pop may still advance real past the claim.
// 2) Copy claimed tasks into dst.
// 3) Commit by setting steal == real to the *current* real (not the claim
//    end) so owner pops during the copy are not rolled back.
Steal::steal_into(dst<Local>) (i32, task.Notified) {
    src<QueueInner> = this.queue_hub
    dst_inner<QueueInner> = dst.queue_hub

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
        n<u32> = size - size / 2
        if n == 0 {
            return io.NotFound, task.notified_from_raw(null)
        }

        // Abort if dst looks more than half full (mother steal_into).
        dst_h<u64> = atomic.load64(&dst_inner.head)
        dst_steal<u32> = head_steal(dst_h)
        if ring_size(dst_inner.tail, dst_steal) > LOCAL_QUEUE_CAPACITY / 2 {
            return io.NotFound, task.notified_from_raw(null)
        }

        steal_to<u32> = real + n
        // Claim: keep steal, advance real.
        new_h<u64> = pack_head(steal, steal_to)
        if atomic.cas64(&src.head, h.(i64), new_h.(i64)) != CAS64_OK {
            continue
        }

        first<u32> = real
        dst_tail<u32> = dst_inner.tail

        // Copy claimed slots into dst, skipping empties: the owner may have
        // popped overlapping indices after our claim (mother allows that).
        // Writing 0 into dst would later pop a null RawTask and SEGV under GC.
        i<u32> = 0
        written<u32> = 0
        while i < n {
            src_idx<u32> = (first + i) & LOCAL_QUEUE_MASK
            bits<u64> = buffer_take(src.buffer, src_idx)
            if bits != 0 {
                dst_idx<u32> = (dst_tail + written) & LOCAL_QUEUE_MASK
                dst_inner.buffer[dst_idx] = bits
                written += 1
            }
            i += 1
        }

        // Commit: steal == real at the *current* real (owner may have popped).
        loop {
            h2<u64> = atomic.load64(&src.head)
            cur_real<u32> = head_real(h2)
            done_h<u64> = pack_head(cur_real, cur_real)
            if atomic.cas64(&src.head, h2.(i64), done_h.(i64)) == CAS64_OK {
                break
            }
        }

        if written == 0 {
            return io.NotFound, task.notified_from_raw(null)
        }

        // Return one task from dst; leave written-1 queued (tight, no holes).
        leave<u32> = written - 1
        ret_pos<u32> = dst_tail + leave
        ret_idx<u32> = ret_pos & LOCAL_QUEUE_MASK
        ret_bits<u64> = buffer_take(dst_inner.buffer, ret_idx)
        if leave > 0 {
            dst_inner.tail = dst_tail + leave
        }
        if ret_bits == 0 {
            return io.NotFound, task.notified_from_raw(null)
        }
        ret_raw<task.RawTask> = ret_bits.(task.RawTask)
        return 0, task.notified_from_raw(ret_raw)
    }
    return io.NotFound, task.notified_from_raw(null)
}


