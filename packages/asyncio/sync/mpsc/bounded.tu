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

// Async recv. Parks on rx_waker between attempts.
async Receiver::recv(){
    loop {
        err<i32>, val<i64> = chan_recv_inner(this.chan)
        if err == 0 return 0, val
        if err == aerr.ChannelClosed return aerr.ChannelClosed, 0
        // RecvEmpty — register and re-check after registering to close the wake gap.
        ctx<u64> = 0
        this.chan.rx_waker.register_by_ref(ctx)
        err2<i32>, val2<i64> = chan_recv_inner(this.chan)
        if err2 == 0 return 0, val2
        if err2 == aerr.ChannelClosed return aerr.ChannelClosed, 0
        // Still empty: yield via the parent runtime.
        return aerr.RecvEmpty, 0
    }
    return 0, 0
}

// Tear down the receiver side. Senders subsequently surface SendNoReceiver.
Receiver::close(){
    this.chan.close_receiver()
}

