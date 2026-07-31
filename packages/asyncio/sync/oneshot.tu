// Single-message channel. State bits track who has the value, who has
// dropped, and who has closed. Receiver::recv waits on rx_waker; senders
// can observe Receiver drop via Sender::closed (uses tx_waker).

use std.atomic
use runtime

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS_OK<i32> = 1

VALUE_SET<i32>  = 0x01
TX_DROPPED<i32> = 0x02
RX_DROPPED<i32> = 0x04
CLOSED<i32>     = 0x08

OS_ERR_SEND_NO_RECEIVER<i32> = 0x0302000B
OS_ERR_ALREADY_CONSUMED<i32> = 0x03020007
OS_ERR_CLOSED<i32>           = 0x03020002
OS_ERR_RECV_EMPTY<i32>       = 0x0302000C

// Shared inner state. State word is atomic; the value slot is published
// via VALUE_SET and only read after the CAS that sets the bit.
mem OneshotInner {
    i32           state       // atomic; bitfield over the constants above
    i64           data_i64
    AtomicWaker*  tx_waker    // arms when sender awaits closed()
    AtomicWaker*  rx_waker    // arms while receiver awaits recv()
}

// Build an empty inner shell.
const OneshotInner::new() OneshotInner {
    s<OneshotInner> = new OneshotInner
    s.state      = 0
    s.data_i64   = 0
    s.tx_waker   = AtomicWaker::new()
    s.rx_waker   = AtomicWaker::new()
    return s
}

// Sender side. Drop the sender once you no longer plan to send.
mem OneshotSender {
    OneshotInner* backing
}

// Receiver side. Cannot be cloned.
mem OneshotReceiver {
    OneshotInner* backing
    i32           consumed   // monotonic 0 -> 1 once the value was taken
}

// Build a (Sender, Receiver) pair sharing one inner.
fn oneshot_channel() (OneshotSender, OneshotReceiver) {
    shell<OneshotInner> = OneshotInner::new()
    s<OneshotSender>   = new OneshotSender { backing: shell }
    r<OneshotReceiver> = new OneshotReceiver { backing: shell, consumed: 0 }
    return s, r
}

// Send the value. Returns SendNoReceiver if the receiver has been dropped
// or closed; AlreadyConsumed if a value is already set.
OneshotSender::send(v<i64>) i32 {
    inner<OneshotInner> = this.backing
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        if (cur & RX_DROPPED) != 0 return OS_ERR_SEND_NO_RECEIVER
        if (cur & CLOSED) != 0     return OS_ERR_SEND_NO_RECEIVER
        if (cur & VALUE_SET) != 0  return OS_ERR_ALREADY_CONSUMED
        newv<i32> = cur | VALUE_SET
        if atomic.cas(addr, cur, newv) == CAS_OK {
            inner.data_i64 = v
            inner.rx_waker.wake()
            return 0
        }
    }
    return 0
}

// Mark the sender dropped. After this, recv eventually surfaces Closed
// when no value was ever set.
OneshotSender::drop_send(){
    inner<OneshotInner> = this.backing
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        newv<i32> = cur | TX_DROPPED
        if atomic.cas(addr, cur, newv) == CAS_OK {
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
    OneshotInner* backing
    i32           stage
}

SenderClosedFut::init(shell<OneshotInner>){
    this.backing = shell
    this.stage = SC_STAGE_INIT
}

SenderClosedFut::poll(ctx){
    inner<OneshotInner> = this.backing
    cur<i32> = atomic.load(&inner.state)
    if (cur & RX_DROPPED) != 0 || (cur & CLOSED) != 0 {
        this.stage = SC_STAGE_DONE
        return runtime.PollReady, 0.(i64)
    }
    inner.tx_waker.register_by_ref(ctx.(u64))
    cur2<i32> = atomic.load(&inner.state)
    if (cur2 & RX_DROPPED) != 0 || (cur2 & CLOSED) != 0 {
        this.stage = SC_STAGE_DONE
        return runtime.PollReady, 0.(i64)
    }
    this.stage = SC_STAGE_WAITING
    return runtime.PollPending
}

// Block until the receiver has dropped (or close() landed). Returns 0.
async OneshotSender::closed(){
    fut<SenderClosedFut> = new SenderClosedFut
    fut.init(this.backing)
    return fut.await
}

// Non-blocking receive. Returns (0, value), (RecvEmpty, 0) when the value
// has not arrived, (Closed, 0) when sender dropped without sending, or
// (AlreadyConsumed, 0) on second call.
OneshotReceiver::try_recv() (i32, i64) {
    if this.consumed == 1 return OS_ERR_ALREADY_CONSUMED, 0
    inner<OneshotInner> = this.backing
    cur<i32> = atomic.load(&inner.state)
    if (cur & VALUE_SET) != 0 {
        this.consumed = 1
        return 0, inner.data_i64
    }
    if (cur & TX_DROPPED) != 0 {
        return OS_ERR_CLOSED, 0
    }
    return OS_ERR_RECV_EMPTY, 0
}

// Mark the receiver dropped or close-requested; sender side surfaces
// SendNoReceiver afterwards.
OneshotReceiver::drop_recv(){
    inner<OneshotInner> = this.backing
    addr<i32*> = &inner.state
    loop {
        cur<i32> = atomic.load(addr)
        newv<i32> = cur | RX_DROPPED
        if atomic.cas(addr, cur, newv) == CAS_OK {
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
    OneshotInner* backing
    i32           stage
    i32           poll_mode   // 1 = closed(), 0 = recv()
}

RecvFut::init(shell<OneshotInner>, poll_mode<i32>){
    this.backing   = shell
    this.stage     = RV_STAGE_INIT
    this.poll_mode = poll_mode
}

RecvFut::poll(ctx){
    shell<OneshotInner> = this.backing
    st<i32> = atomic.load(&shell.state)
    if this.poll_mode == 1 {
        if (st & TX_DROPPED) != 0 || (st & CLOSED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, 0.(i64)
        }
    } else {
        if (st & VALUE_SET) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, shell.data_i64
        }
        if (st & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, OS_ERR_CLOSED.(i64)
        }
    }

    shell.rx_waker.register_by_ref(ctx.(u64))
    st2<i32> = atomic.load(&shell.state)
    if this.poll_mode == 1 {
        if (st2 & TX_DROPPED) != 0 || (st2 & CLOSED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, 0.(i64)
        }
    } else {
        if (st2 & VALUE_SET) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, shell.data_i64
        }
        if (st2 & TX_DROPPED) != 0 {
            this.stage = RV_STAGE_DONE
            return runtime.PollReady, OS_ERR_CLOSED.(i64)
        }
    }
    this.stage = RV_STAGE_WAITING
    return runtime.PollPending
}

// Receive the value. Single-shot: subsequent calls return AlreadyConsumed.
async OneshotReceiver::recv(){
    if this.consumed == 1 return OS_ERR_ALREADY_CONSUMED, 0.(i64)
    fut<RecvFut> = new RecvFut
    fut.init(this.backing, 0)
    val<i64> = fut.await
    if val.(i32) == OS_ERR_CLOSED return OS_ERR_CLOSED, 0.(i64)
    this.consumed = 1
    return 0, val
}

// Block until the sender has dropped or sent.
async OneshotReceiver::closed(){
    fut<RecvFut> = new RecvFut
    fut.init(this.backing, 1)
    return fut.await
}
