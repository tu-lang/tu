// Unbounded mpsc: same Sender/Receiver shape as bounded but without the
// BatchSemaphore gate. send() never blocks on backpressure.

fn mpsc_unbounded() (MpscSender, MpscReceiver) {
    c<Chan> = Chan::new(0)
    return new MpscSender { link: c }, new MpscReceiver { link: c }
}
