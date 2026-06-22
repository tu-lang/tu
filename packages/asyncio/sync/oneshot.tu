// Single-message channel. State bits track who has the value, who has
// dropped, and who has closed. Receiver::recv waits on rx_waker; senders
// can observe Receiver drop via Sender::closed (uses tx_waker).

use std.atomic
use runtime
use asyncio.error as aerr

VALUE_SET<i32>  = 0b00001
TX_DROPPED<i32> = 0b00010
RX_DROPPED<i32> = 0b00100
CLOSED<i32>     = 0b01000

// Shared inner state. State word is atomic; the value slot is published
// via VALUE_SET and only read after the CAS that sets the bit.
mem OneshotInner {
    i32           state       // atomic; bitfield over the constants above
    i64           value_slot
    AtomicWaker*  tx_waker    // arms when sender awaits closed()
    AtomicWaker*  rx_waker    // arms while receiver awaits recv()
}

// Build an empty inner shell.
const OneshotInner::new() OneshotInner {
    s<OneshotInner> = new OneshotInner
    s.state      = 0
    s.value_slot = 0
    s.tx_waker   = AtomicWaker::new()
    s.rx_waker   = AtomicWaker::new()
    return s
}

// Sender side. Drop the sender once you no longer plan to send.
mem OneshotSender {
    OneshotInner* inner
}

// Receiver side. Cannot be cloned.
mem OneshotReceiver {
    OneshotInner* inner
    i32           consumed   // monotonic 0 -> 1 once the value was taken
}

// Build a (Sender, Receiver) pair sharing one inner.
const oneshot_channel() (OneshotSender, OneshotReceiver) {
    inner<OneshotInner> = OneshotInner::new()
    s<OneshotSender>   = new OneshotSender { inner: inner }
    r<OneshotReceiver> = new OneshotReceiver { inner: inner, consumed: 0 }
    return s, r
}

// Send the value. Returns asyncio.error.SendNoReceiver if the receiver
// has been dropped or closed; AlreadyConsumed if a value is already set.
OneshotSender::send(v<i64>) i32 {
    inner<OneshotInner> = this.inner
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        if (cur & RX_DROPPED) != 0 return aerr.SendNoReceiver
        if (cur & CLOSED) != 0     return aerr.SendNoReceiver
        if (cur & VALUE_SET) != 0  return aerr.AlreadyConsumed
        newv<i32> = cur | VALUE_SET
        if atomic.cas(addr, cur, newv) != 0 {
            inner.value_slot = v
            // Wake the receiver if it's waiting on the value.
            inner.rx_waker.wake()
            return 0
        }
    }
    return 0
}

// Mark the sender dropped. After this, recv eventually surfaces Closed
// when no value was ever set.
OneshotSender::drop_send(){
    inner<OneshotInner> = this.inner
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        newv<i32> = cur | TX_DROPPED
        if atomic.cas(addr, cur, newv) != 0 {
            inner.rx_waker.wake()
            return
        }
    }
}

// Async leaf for Sender::closed(); resolves once Receiver drops or marks
// the channel closed.
SC_STAGE_INIT<i32>    = 0
SC_STAGE_WAITING<i32> = 1
SC_STAGE_DONE<i32>    = 2

mem SenderClosedFut: async {
    OneshotInner* inner
    i32           stage
}

SenderClosedFut::init(inner<OneshotInner>){
    this.inner = inner
    this.stage = SC_STAGE_INIT
}

SenderClosedFut::poll(ctx){
    inner<OneshotInner> = this.inner
    cur<i32> = atomic.load(&inner.state)
    if (cur & RX_DROPPED) != 0 || (cur & CLOSED) != 0 {
        this.stage = SC_STAGE_DONE
        return runtime.PollReady, 0
    }
    inner.tx_waker.register_by_ref(ctx.(u64))
    cur = atomic.load(&inner.state)
    if (cur & RX_DROPPED) != 0 || (cur & CLOSED) != 0 {
        this.stage = SC_STAGE_DONE
        return runtime.PollReady, 0
    }
    this.stage = SC_STAGE_WAITING
    return runtime.PollPending
}

// Block until the receiver has dropped (or close() landed). Returns 0.
async OneshotSender::closed(){
    fut<SenderClosedFut> = new SenderClosedFut
    fut.init(this.inner)
    return fut.await
}

// Non-blocking receive. Returns (0, value), (RecvEmpty, 0) when the value
// has not arrived, (Closed, 0) when sender dropped without sending, or
// (AlreadyConsumed, 0) on second call.
OneshotReceiver::try_recv() (i32, i64) {
    if this.consumed == 1 return aerr.AlreadyConsumed, 0
    inner<OneshotInner> = this.inner
    cur<i32> = atomic.load(&inner.state)
    if (cur & VALUE_SET) != 0 {
        this.consumed = 1
        return 0, inner.value_slot
    }
    if (cur & TX_DROPPED) != 0 {
        return aerr.Closed, 0
    }
    return aerr.RecvEmpty, 0
}

// Mark the receiver dropped or close-requested; sender side surfaces
// SendNoReceiver afterwards.
OneshotReceiver::drop_recv(){
    inner<OneshotInner> = this.inner
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        newv<i32> = cur | RX_DROPPED
        if atomic.cas(addr, cur, newv) != 0 {
            inner.tx_waker.wake()
            return
        }
    }
}

// Async leaf for Receiver::recv() / Receiver::closed().
RV_STAGE_INIT<i32>    = 0
RV_STAGE_WAITING<i32> = 1
RV_STAGE_DONE<i32>    = 2

// Await-shaped recv future.
mem RecvFut: async {
    OneshotInner* inner
    i32           stage
    i32           closed_only   // 1 for closed(), 0 for recv()
}

RecvFut::init(inner<OneshotInner>, closed_only<i32>){
    this.inner       = inner
    this.stage       = RV_STAGE_INIT
    this.closed_only = closed_only
}

RecvFut::poll(ctx){
    inner<OneshotInner> = this.inner
    cur<i32> = atomic.load(&inner.state)

    if this.closed_only == 1 {
        if (cur & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, 0
        }
    } else {
        if (cur & VALUE_SET) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, inner.value_slot
        }
        if (cur & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, aerr.Closed
        }
    }

    inner.rx_waker.register_by_ref(ctx.(u64))
    // Re-check after registering so we don't miss a concurrent send/drop.
    cur = atomic.load(&inner.state)
    if this.closed_only == 1 {
        if (cur & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, 0
        }
    } else {
        if (cur & VALUE_SET) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, inner.value_slot
        }
        if (cur & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, aerr.Closed
        }
    }
    this.stage = RV_STAGE_WAITING
    return runtime.PollPending
}

// Receive the value. Single-shot: subsequent calls return AlreadyConsumed.
async OneshotReceiver::recv(){
    if this.consumed == 1 return aerr.AlreadyConsumed, 0.(i64)
    fut<RecvFut> = new RecvFut
    fut.init(this.inner, 0)
    val<i64> = fut.await
    if val == aerr.Closed.(i64) return aerr.Closed, 0.(i64)
    this.consumed = 1
    return 0, val
}

// Block until the sender has dropped or sent.
async OneshotReceiver::closed(){
    fut<RecvFut> = new RecvFut
    fut.init(this.inner, 1)
    return fut.await
}

