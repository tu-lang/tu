// One-shot shutdown signal. Sender::shutdown flips done=1 and wakes the
// receiver; Receiver::wait blocks until done.

use runtime

// Shared inner state behind the Sender / Receiver pair.
mem ShutdownInner {
    i32                done       // 0 / 1
    runtime.MutexInter lock
    runtime.Note       notify
}

// Sender side; shutdown() is idempotent.
mem ShutdownSender {
    ShutdownInner* inner
}

// Receiver side; wait() blocks until done is set.
mem ShutdownReceiver {
    ShutdownInner* inner
}

// Build a fresh (Sender, Receiver) pair sharing one Inner.
const shutdown_channel() (ShutdownSender, ShutdownReceiver) {
    inner<ShutdownInner> = new ShutdownInner
    inner.done = 0
    inner.lock.init()
    inner.notify.Clear()
    s<ShutdownSender>   = new ShutdownSender   { inner: &inner }
    r<ShutdownReceiver> = new ShutdownReceiver { inner: &inner }
    return s, r
}

// Flip done=1 and wake the receiver. Idempotent.
ShutdownSender::shutdown(){
    inner<ShutdownInner> = this.inner
    inner.lock.lock()
    if inner.done == 0 {
        inner.done = 1
        inner.lock.unlock()
        inner.notify.Wake()
        return
    }
    inner.lock.unlock()
}

// Block until done. Spurious wake-ups loop back.
ShutdownReceiver::wait(){
    inner<ShutdownInner> = this.inner
    loop {
        inner.lock.lock()
        if inner.done == 1 {
            inner.lock.unlock()
            return
        }
        inner.lock.unlock()
        inner.notify.Sleep()
        inner.notify.Clear()
    }
}

