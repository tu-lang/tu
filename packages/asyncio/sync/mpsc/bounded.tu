// Bounded mpsc Sender / Receiver. Sender::send awaits BatchSemaphore;
// Receiver::recv parks on rx_waker until a producer wakes it.

use runtime
use asyncio.error as aerr

// Sender holds a strong reference into Chan. Cloning bumps tx_count.
mem Sender {
    Chan* chan
}

// Receiver is unique; only one outstanding Receiver per channel.
mem Receiver {
    Chan* chan
}

// Build a (Sender, Receiver) pair with capacity `cap` permits.
const mpsc_bounded(cap<u32>) (Sender, Receiver) {
    sem<BatchSemaphore> = BatchSemaphore::new(cap)
    c<Chan>             = Chan::new(sem)
    return new Sender { chan: c }, new Receiver { chan: c }
}

// Cloneable strong sender; tracks tx_count so drop_last_sender wakes the receiver.
Sender::clone() Sender {
    this.chan.inc_tx()
    return new Sender { chan: this.chan }
}

// Drop a sender. Last drop closes the channel for the receiver.
Sender::drop_send(){
    this.chan.drop_last_sender()
}

// Non-blocking send. Returns SendFull when no permits are available.
Sender::try_send(v<i64>) i32 {
    return chan_send_inner(this.chan, v)
}

// Async send: awaits a permit before pushing. Cancellation between the
// permit grant and the actual push leaks one permit but keeps the queue
// consistent; tokio behaves the same way.
async Sender::send(v<i64>){
    if this.chan.is_closed() return aerr.ChannelClosed
    err<i32> = this.chan.semaphore.acquire(1).await
    if err != 0 return err
    perr<i32> = this.chan.tx.push(v)
    if perr != 0 {
        this.chan.semaphore.release(1)
        return perr
    }
    this.chan.rx_waker.wake()
    return 0
}

// Non-blocking recv. Returns RecvEmpty / ChannelClosed when nothing is
// ready or all senders are gone, respectively.
Receiver::try_recv() (i32, i64) {
    return chan_recv_inner(this.chan)
}

// Async leaf for Receiver::recv(); parks on rx_waker until a value is
// published or every sender drops. The received value is stashed in
// this.val, and poll returns the error code as its ready result.
mem RecvFut: async {
    Chan* chan   // channel we pull from
    i32   err    // 0 on success, ChannelClosed once senders are gone
    i64   val    // received value when err == 0
}

// Initialise before the first poll.
RecvFut::init(chan<Chan>){
    this.chan = chan
    this.err  = 0
    this.val  = 0
}

// Pop a value or park on rx_waker. Re-checks after registering the waker
// to close the wake gap. Returns (PollReady, err) with the value in
// this.val, or PollPending while the queue is still empty.
RecvFut::poll(ctx){
    c<Chan> = this.chan
    err<i32>, val<i64> = chan_recv_inner(c)
    if err == 0 {
        this.err = 0
        this.val = val
        return runtime.PollReady, 0
    }
    if err == aerr.ChannelClosed {
        this.err = aerr.ChannelClosed
        this.val = 0
        return runtime.PollReady, aerr.ChannelClosed
    }
    // RecvEmpty: register, then re-check to avoid missing a concurrent send.
    c.rx_waker.register_by_ref(ctx.(u64))
    err2<i32>, val2<i64> = chan_recv_inner(c)
    if err2 == 0 {
        this.err = 0
        this.val = val2
        return runtime.PollReady, 0
    }
    if err2 == aerr.ChannelClosed {
        this.err = aerr.ChannelClosed
        this.val = 0
        return runtime.PollReady, aerr.ChannelClosed
    }
    return runtime.PollPending
}

// Async recv. Awaits RecvFut, which parks on rx_waker until data arrives
// or all senders drop. Returns (0, value) or (ChannelClosed, 0).
async Receiver::recv(){
    fut<RecvFut> = new RecvFut
    fut.init(this.chan)
    err<i32> = fut.await
    return err, fut.val
}

// Tear down the receiver side. Senders subsequently surface SendNoReceiver.
Receiver::close(){
    this.chan.close_receiver()
}

