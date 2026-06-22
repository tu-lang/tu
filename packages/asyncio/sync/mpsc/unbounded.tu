// Unbounded mpsc: same Sender/Receiver shape as bounded but without the
// BatchSemaphore gate. send() never blocks on backpressure.

use asyncio.error as aerr

// Build a (Sender, Receiver) pair with no permit gate. Chan::new returns
// a heap pointer; pass it through.
const mpsc_unbounded() (Sender, Receiver) {
    c<Chan> = Chan::new(null)
    return new Sender { chan: c }, new Receiver { chan: c }
}

