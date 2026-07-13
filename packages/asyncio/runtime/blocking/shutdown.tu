// One-shot shutdown signal. Sender::shutdown flips done=1 and wakes the
// receiver; Receiver::wait blocks until done.

use runtime

// Shared inner state behind the Sender / Receiver pair.
mem ShutdownInner {
    i32                done       // 0 / 1
    runtime.MutexInter* lock
    runtime.Note       notify
}

// Sender side; shutdown() is idempotent.
mem ShutdownSender {
    ShutdownInner* shared_hub
}

// Receiver side; wait() blocks until done is set.
mem ShutdownReceiver {
    ShutdownInner* shared_hub
}

// Build a fresh (Sender, Receiver) pair sharing one Inner.
fn shutdown_channel() (ShutdownSender, ShutdownReceiver) {
    hub<ShutdownInner> = new ShutdownInner
    hub.done = 0
    hub.lock = new runtime.MutexInter
    hub.lock.init()
    hub.notify.Clear()
    s<ShutdownSender>   = new ShutdownSender   { shared_hub: hub }
    r<ShutdownReceiver> = new ShutdownReceiver { shared_hub: hub }
    return s, r
}

// Flip done=1 and wake the receiver. Idempotent.
ShutdownSender::shutdown(){
    hub<ShutdownInner> = this.shared_hub
    hub.lock.lock()
    if hub.done == 0 {
        hub.done = 1
        hub.lock.unlock()
        hub.notify.Wake()
        return
    }
    hub.lock.unlock()
}

// Block until done. Spurious wake-ups loop back.
ShutdownReceiver::wait(){
    hub<ShutdownInner> = this.shared_hub
    loop {
        hub.lock.lock()
        if hub.done == 1 {
            hub.lock.unlock()
            return
        }
        hub.lock.unlock()
        hub.notify.Sleep()
        hub.notify.Clear()
    }
}
