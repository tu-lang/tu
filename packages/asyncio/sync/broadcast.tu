// Multi-producer multi-receiver fan-out.
use std
use std.atomic
use runtime

BCAST_LAGGED<i32> = 0x03020003

mem Broadcast {
    i64*    slot_store
    u64     cap
    u64     tail         // atomic; messages sent
    u64     lapped       // atomic; full laps
    Notify* wake_notify
}

const Broadcast::new(cap<u64>) Broadcast {
    b<Broadcast> = new Broadcast
    b.slot_store = runtime.malloc(sizeof(i64) * cap, 0.(i8), 1.(i8))
    b.cap = cap
    b.tail = 0
    b.lapped = 0
    b.wake_notify = Notify::new()
    return b
}

fn broadcast_publish(b<Broadcast>, v<i64>) i32 {
    slot<u64> = atomic.xadd64(&b.tail, 1)
    idx<u64> = slot % b.cap
    b.slot_store[idx] = v
    if (slot + 1) % b.cap == 0 atomic.xadd64(&b.lapped, 1)
    b.wake_notify.notify_waiters()
    return 0
}

mem BroadcastSender {
    Broadcast* backing
}

mem BroadcastReceiver {
    Broadcast* backing
    u64        last_seen
}

fn broadcast_channel(cap<u64>) (BroadcastSender, BroadcastReceiver) {
    b<Broadcast> = Broadcast::new(cap)
    return new BroadcastSender { backing: b }, new BroadcastReceiver { backing: b, last_seen: 0 }
}

BroadcastSender::send(v<i64>) i32 {
    return broadcast_publish(this.backing, v)
}

// Async leaf for recv.
mem BroadcastRecvFut: async {
    Broadcast* owner
    u64        cursor
    i32        stage
    Notified*  notify_fut
    i32        ready_err
    i64        ready_val
}

BroadcastRecvFut::init(owner<Broadcast>, cursor<u64>){
    this.owner = owner
    this.cursor = cursor
    this.stage = 0
    this.notify_fut = null
    this.ready_err = 0
    this.ready_val = 0
}

BroadcastRecvFut::poll(ctx){
    hub<Broadcast> = this.owner
    cur_tail<u64> = atomic.load64(&hub.tail)
    if this.cursor < cur_tail {
        if cur_tail - this.cursor > hub.cap {
            this.cursor = cur_tail - hub.cap
            idx<u64> = this.cursor % hub.cap
            this.cursor += 1
            this.ready_err = BCAST_LAGGED
            this.ready_val = hub.slot_store[idx]
            return runtime.PollReady, BCAST_LAGGED
        }
        idx<u64> = this.cursor % hub.cap
        this.cursor += 1
        this.ready_err = 0
        this.ready_val = hub.slot_store[idx]
        return runtime.PollReady, 0.(i64)
    }
    if this.notify_fut == null {
        this.notify_fut = notified_from_notify(hub.wake_notify)
    }
    nfy<Notified> = this.notify_fut
    code<i32> = nfy.poll(ctx)
    if code == runtime.PollReady {
        this.notify_fut = null
    }
    return runtime.PollPending
}

async BroadcastReceiver::recv(){
    fut<BroadcastRecvFut> = broadcast_recv_fut(this)
    err<i32> = fut.await
    this.last_seen = fut.cursor
    return err, fut.ready_val
}

fn broadcast_recv_fut(rx<BroadcastReceiver>) BroadcastRecvFut {
    fut<BroadcastRecvFut> = new BroadcastRecvFut
    fut.init(rx.backing, rx.last_seen)
    return fut
}
