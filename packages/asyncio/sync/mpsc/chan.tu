// Shared multi-producer single-consumer channel state. Holds the
// producer queue, the rx waker, the close flag, and (for bounded
// channels) the BatchSemaphore that gates send().

use std.atomic
use runtime
use asyncio.sync as libsync

// Backed-by either a real BatchSemaphore (bounded) or zero (unbounded).
mem Chan {
    ListTx*             producer
    u64                 rx_waker_bits
    u64                 notify_rx_closed_bits
    u64                 semaphore_bits    // 0 = unbounded; else BatchSemaphore*
    i32                 tx_count          // atomic; live Sender clones
    i32                 tx_weak_count     // atomic; weak senders
    runtime.MutexInter* rx_lock
    ListRx*             consumer
    i32                 rx_closed         // 0/1 monotonic
}

// Build a Chan with `sem_bits` (0 for unbounded). tx_count starts at 1.
const Chan::new(sem_bits<u64>) Chan {
    c<Chan> = new Chan
    prod<ListTx>, cons<ListRx> = mpsc_list_new()
    c.producer              = prod
    c.consumer              = cons
    c.rx_waker_bits         = libsync.atomic_waker_new_raw()
    c.notify_rx_closed_bits = libsync.notify_new_raw()
    c.semaphore_bits        = sem_bits
    c.tx_count              = 1
    c.tx_weak_count         = 0
    c.rx_lock               = new runtime.MutexInter
    c.rx_lock.init()
    c.rx_closed             = 0
    return c
}

// Atomically increment Sender count.
Chan::inc_tx(){
    atomic.xadd(&this.tx_count, 1)
}

TX_COUNT_DEC<u32> = 0xFFFFFFFF

// Atomically decrement Sender count; mark the channel closed for recv
// once the last Sender drops.
Chan::drop_last_sender() i32 {
    n<i32> = atomic.xadd(&this.tx_count, TX_COUNT_DEC)
    if n == 1 {
        libsync.atomic_waker_wake_by_ref_raw(this.rx_waker_bits)
        return 1
    }
    return 0
}

// Mark the receiver gone; senders surface SendNoReceiver going forward.
Chan::close_receiver(){
    this.rx_lock.lock()
    if this.rx_closed == 0 {
        this.rx_closed = 1
    }
    this.rx_lock.unlock()
    if this.semaphore_bits != 0 libsync.batch_sem_close_raw(this.semaphore_bits)
    libsync.notify_waiters_raw(this.notify_rx_closed_bits)
}

// True when the receiver has dropped or been closed.
Chan::is_closed() i32 {
    if this.rx_closed == 1 return 1
    return 0
}

// Non-blocking send. Bounded variant returns SendFull when permits run
// out; unbounded always allocates a slot (memory permitting).
fn chan_send_inner(c<Chan>, v<i64>) i32 {
    if c.is_closed() return RecvErrorClosed
    if c.semaphore_bits != 0 {
        err<i32> = libsync.batch_sem_try_acquire_raw(c.semaphore_bits, 1)
        if err != 0 return err
    }
    perr<i32> = c.producer.publish(v)
    if perr != 0 {
        if c.semaphore_bits != 0 libsync.batch_sem_release_raw(c.semaphore_bits, 1)
        return perr
    }
    libsync.atomic_waker_wake_by_ref_raw(c.rx_waker_bits)
    return 0
}

// Non-blocking recv. Returns (RecvEmpty, 0) when no slot is published
// yet, (ChannelClosed, 0) when the senders are gone and the queue is
// drained.
fn chan_recv_inner(c<Chan>) (i32, i64) {
    code<i32>, data<i64> = c.consumer.pop()
    if code == 0 {
        if c.semaphore_bits != 0 libsync.batch_sem_release_raw(c.semaphore_bits, 1)
        return 0, data
    }
    if atomic.load(&c.tx_count) == 0 return RecvErrorClosed, 0
    return RecvErrorEmpty, 0
}
