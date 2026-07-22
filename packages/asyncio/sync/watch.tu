// Single-slot value with version counter (tokio sync::watch).
use std.atomic
use runtime

WATCH_CHAN_CLOSED<i32> = 0x03020002

// Shared watch hub; version bumps on each send.
mem Watch {
    u64     slot_bits
    u64     version       // atomic; monotonic on send
    Notify* wake_notify   // tokio: notify_rx
    Notify* tx_wake       // tokio: notify_tx for Sender::closed
    i32     rx_live       // live receiver count
    i32     tx_dropped    // sender dropped flag
}

const Watch::new(value<u64>) Watch {
    w<Watch> = new Watch
    w.slot_bits = value
    w.version = 1
    w.wake_notify = Notify::new()
    w.tx_wake = Notify::new()
    w.rx_live = 1
    w.tx_dropped = 0
    return w
}

mem WatchSender {
    Watch* backing
}

mem WatchReceiver {
    Watch* backing
    u64    last_seen_version
}

fn watch_channel(value<u64>) (WatchSender, WatchReceiver) {
    w<Watch> = Watch::new(value)
    return new WatchSender { backing: w }, new WatchReceiver { backing: w, last_seen_version: 1 }
}

WatchSender::send(value<u64>){
    w<Watch> = this.backing
    w.slot_bits = value
    atomic.xadd64(&w.version, 1)
    w.wake_notify.notify_waiters()
}

WatchReceiver::borrow() u64 {
    return this.backing.slot_bits
}

WatchReceiver::borrow_and_update() u64 {
    w<Watch> = this.backing
    this.last_seen_version = atomic.load64(&w.version)
    return w.slot_bits
}

// Decrement live receivers and wake sender closed waiters.
WatchReceiver::drop_recv(){
    w<Watch> = this.backing
    w.rx_live = w.rx_live - 1
    w.tx_wake.notify_waiters()
}

WatchSender::drop_send(){
    w<Watch> = this.backing
    w.tx_dropped = 1
    w.wake_notify.notify_waiters()
}

// Async leaf for Receiver::changed().
mem WatchChangedFut: async {
    WatchReceiver* rx_side
    i32            stage
    Notified*      pending_nf
}

WatchChangedFut::init(rx<WatchReceiver>){
    this.rx_side = rx
    this.stage = 0
    this.pending_nf = null
}

WatchChangedFut::poll(ctx){
    rx<WatchReceiver> = this.rx_side
    hub<Watch> = rx.backing
    if hub.tx_dropped != 0 {
        return runtime.PollReady, WATCH_CHAN_CLOSED
    }
    cur_ver<u64> = atomic.load64(&hub.version)
    if cur_ver != rx.last_seen_version {
        rx.last_seen_version = cur_ver
        return runtime.PollReady, 0.(i64)
    }
    if this.pending_nf == null {
        this.pending_nf = notified_from_notify(hub.wake_notify)
    }
    nfy<Notified> = this.pending_nf
    code<i32> = nfy.poll(ctx)
    if code == runtime.PollReady {
        this.pending_nf = null
    }
    return runtime.PollPending
}

async WatchReceiver::changed(){
    fut<WatchChangedFut> = new WatchChangedFut
    fut.init(this)
    err<i32> = fut.await
    return err
}

// Async leaf for Sender::closed().
mem WatchSenderClosedFut: async {
    Watch*    hub
    Notified* pending_nf
}

WatchSenderClosedFut::init(hub<Watch>){
    this.hub = hub
    this.pending_nf = null
}

WatchSenderClosedFut::poll(ctx){
    hub<Watch> = this.hub
    if hub.rx_live == 0 {
        return runtime.PollReady, 0.(i64)
    }
    if this.pending_nf == null {
        this.pending_nf = notified_from_notify(hub.tx_wake)
    }
    nfy<Notified> = this.pending_nf
    code<i32> = nfy.poll(ctx)
    if code == runtime.PollReady {
        this.pending_nf = null
        if hub.rx_live == 0 {
            return runtime.PollReady, 0.(i64)
        }
    }
    return runtime.PollPending
}

async WatchSender::closed(){
    fut<WatchSenderClosedFut> = new WatchSenderClosedFut
    fut.init(this.backing)
    return fut.await
}
