// Single-slot value with an atomic version counter. Receivers subscribe
// via changed(); send() bumps version and wakes everyone.

use std.atomic
use runtime
use asyncio.error as aerr

// Inner state shared by Sender and every Receiver clone.
mem Watch {
    u64          value         // raw bits; reader casts via slot.(SomeMem)
    u64          version       // atomic; monotonically increasing
    sync.Notify* changed
    i32          tx_dropped    // atomic 0/1
}

// Build a Watch initialised to `value`. version starts at 1 so receivers
// constructed against the seed see no spurious changed() event.
const Watch::new(value<u64>) Watch {
    w<Watch> = new Watch
    w.value      = value
    w.version    = 1
    w.changed    = sync.Notify::new()
    w.tx_dropped = 0
    return w
}

// Sender side. Cloning bumps no counter; senders are reference-equal.
mem WatchSender {
    Watch* inner
}

// Receiver tracks the last version it observed.
mem WatchReceiver {
    Watch* inner
    u64    last_seen_version
}

// Build a (Sender, Receiver) pair starting at the seed value.
// Watch::new() already returns a heap pointer; pass it through.
const watch_channel(value<u64>) (WatchSender, WatchReceiver) {
    w<Watch> = Watch::new(value)
    s<WatchSender>   = new WatchSender   { inner: w }
    r<WatchReceiver> = new WatchReceiver { inner: w, last_seen_version: 1 }
    return s, r
}

// Publish a new value; bumps version and wakes every receiver.
WatchSender::send(value<u64>){
    inner<Watch> = this.inner
    inner.value = value
    atomic.xadd64(&inner.version, 1)
    inner.changed.notify_waiters()
}

// Read the current value without waiting.
WatchReceiver::borrow() u64 {
    return this.inner.value
}

// Wait until version > last_seen_version, then update the cursor.
async WatchReceiver::changed(){
    inner<Watch> = this.inner
    loop {
        cur<u64> = atomic.load64(&inner.version)
        if cur > this.last_seen_version {
            this.last_seen_version = cur
            return 0
        }
        if atomic.load(&inner.tx_dropped) == 1 return aerr.ChannelClosed
        code<i32> = inner.changed.notified().await
        if code != 0 return code
    }
    return 0
}

// Sender side: drop tracking so receivers can short-circuit changed().
WatchSender::drop_send(){
    inner<Watch> = this.inner
    atomic.store(&inner.tx_dropped, 0, 1)
    inner.changed.notify_waiters()
}

// Receiver side: wait for the sender to drop. Returns immediately when
// already dropped.
async WatchSender::closed(){
    inner<Watch> = this.inner
    loop {
        if atomic.load(&inner.tx_dropped) == 1 return 0
        inner.changed.notified().await
    }
    return 0
}

