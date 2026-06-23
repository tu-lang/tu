// Shared multi-producer single-consumer channel state. Holds the
// producer queue, the rx waker, the close flag, and (for bounded
// channels) the BatchSemaphore that gates send().

use std.atomic
use runtime
use sync
use asyncio.error as aerr

// Backed-by either a real BatchSemaphore (bounded) or null (unbounded).
mem Chan {
    ListTx*               tx
    sync.AtomicWaker*     rx_waker
    sync.Notify*          notify_rx_closed
    BatchSemaphore*       semaphore           // null for unbounded channels
    i32                   tx_count            // atomic; live Sender clones
    i32                   tx_weak_count       // atomic; weak senders that don't keep the channel open
    runtime.MutexInter    rx_lock
    ListRx*               rx
    i32                   rx_closed           // 0/1 monotonic
}

// Build a Chan with `sem` (or null for unbounded). tx_count starts at 1.
// list_new() returns heap-pointer ListTx / ListRx; assign them straight
// into the Chan fields (do NOT `&tx` / `&rx` — those are stack slots).
const Chan::new(sem<BatchSemaphore>) Chan {
    c<Chan> = new Chan
    tx<ListTx>, rx<ListRx> = list_new()
    c.tx               = tx
    c.rx               = rx
    c.rx_waker         = sync.AtomicWaker::new()
    c.notify_rx_closed = sync.Notify::new()
    c.semaphore        = sem
    c.tx_count         = 1
    c.tx_weak_count    = 0
    c.rx_lock.init()
    c.rx_closed        = 0
    return c
}

// Atomically increment Sender count.
Chan::inc_tx(){
    atomic.xadd(&this.tx_count, 1)
}

// Atomically decrement Sender count; mark the channel closed for recv
// once the last Sender drops.
Chan::drop_last_sender() bool {
    n<i32> = atomic.xadd(&this.tx_count, -1.(i32).(u32))
    if n == 1 {
        // Last sender just left; wake any waiting receiver so it surfaces
        // ChannelClosed instead of waiting forever.
        this.rx_waker.wake()
        return true
    }
    return false
}

// Mark the receiver gone; senders surface SendNoReceiver going forward.
Chan::close_receiver(){
    this.rx_lock.lock()
    if this.rx_closed == 0 {
        this.rx_closed = 1
    }
    this.rx_lock.unlock()
    if this.semaphore != null this.semaphore.close()
    this.notify_rx_closed.notify_waiters()
}

// True when the receiver has dropped or been closed.
Chan::is_closed() bool {
    if this.rx_closed == 1 return true
    return false
}

// Non-blocking send. Bounded variant returns SendFull when permits run
// out; unbounded always allocates a slot (memory permitting).
fn chan_send_inner(c<Chan>, v<i64>) i32 {
    if c.is_closed() return aerr.ChannelClosed
    if c.semaphore != null {
        err<i32> = c.semaphore.try_acquire(1)
        if err != 0 return err
    }
    perr<i32> = c.tx.push(v)
    if perr != 0 {
        if c.semaphore != null c.semaphore.release(1)
        return perr
    }
    c.rx_waker.wake()
    return 0
}

// Non-blocking recv. Returns (RecvEmpty, 0) when no slot is published
// yet, (ChannelClosed, 0) when the senders are gone and the queue is
// drained.
fn chan_recv_inner(c<Chan>) (i32, i64) {
    err<i32>, val<i64> = c.rx.pop()
    if err == 0 {
        if c.semaphore != null c.semaphore.release(1)
        return 0, val
    }
    // Empty: differentiate "wait for more" from "channel closed".
    if atomic.load(&c.tx_count) == 0 return aerr.ChannelClosed, 0
    return aerr.RecvEmpty, 0
}

