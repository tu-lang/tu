// Multi-producer multi-receiver fan-out channel. Backed by a fixed-size
// ring; receivers track their last-seen sequence number and surface
// asyncio.error.Lagged when they fall behind by more than `cap`.

use std
use std.atomic
use runtime
use asyncio.error as aerr

// Inner ring shared by every Sender / Receiver. tail is the next slot
// to write; lapped tracks how many full sweeps have happened so
// receivers can detect "this ring slot was overwritten before I read it".
mem Broadcast {
    i64*         ring        // length cap
    u64          cap
    u64          tail        // atomic; total messages ever sent
    u64          lapped      // atomic; sweeps written
    sync.Notify* changed
}

// Build a Broadcast with capacity cap (must be > 0).
const Broadcast::new(cap<u64>) Broadcast* {
    b<Broadcast> = new Broadcast
    b.ring    = std.malloc(sizeof(i64) * cap)
    b.cap     = cap
    b.tail    = 0
    b.lapped  = 0
    b.changed = sync.Notify::new()
    return &b
}

// Atomic publish: write into the next slot, bump tail, wake every
// receiver currently parked on `changed`.
fn broadcast_publish(b<Broadcast>, v<i64>) i32 {
    slot<u64> = atomic.xadd64(&b.tail, 1)
    idx<u64> = slot % b.cap
    b.ring[idx] = v
    if (slot + 1) % b.cap == 0 {
        atomic.xadd64(&b.lapped, 1)
    }
    b.changed.notify_waiters()
    return 0
}

// Sender side. Cloneable; cloning is just copying the pointer.
mem BroadcastSender {
    Broadcast* inner
}

// Receiver tracks its own cursor; lagging receivers surface Lagged.
mem BroadcastReceiver {
    Broadcast* inner
    u64        last_seen
}

// Build a (Sender, Receiver) pair sharing one ring.
const broadcast_channel(cap<u64>) (BroadcastSender, BroadcastReceiver) {
    b<Broadcast> = Broadcast::new(cap)
    s<BroadcastSender>   = new BroadcastSender   { inner: &b }
    r<BroadcastReceiver> = new BroadcastReceiver { inner: &b, last_seen: 0 }
    return s, r
}

// Publish a value; never blocks.
BroadcastSender::send(v<i64>) i32 {
    return broadcast_publish(this.inner, v)
}

// Receive the next value, awaiting one if needed. Returns
//   (0, value)        — fresh delivery
//   (Lagged, value)   — caller missed one or more messages; cursor advanced
//   (other err, 0)    — propagated from Notify
async BroadcastReceiver::recv(){
    inner<Broadcast> = this.inner
    loop {
        cur_tail<u64> = atomic.load64(&inner.tail)
        if this.last_seen < cur_tail {
            // Detect lap: if we're more than cap behind, fast-forward.
            if cur_tail - this.last_seen > inner.cap {
                this.last_seen = cur_tail - inner.cap
                idx<u64> = this.last_seen % inner.cap
                this.last_seen += 1
                return aerr.Lagged, inner.ring[idx]
            }
            idx<u64> = this.last_seen % inner.cap
            this.last_seen += 1
            return 0, inner.ring[idx]
        }
        code<i32> = inner.changed.notified().await
        if code != 0 return code, 0
    }
    return 0, 0
}

