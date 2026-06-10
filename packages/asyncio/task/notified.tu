// Notified: thin wrapper around a RawTask that is queued/queueable
// Related: packages-asyncio-runtime task 3.24, R5.5, R8.1
// Design: design §10
//
// The harness and schedulers move tasks through the system as `Notified`
// values.  Notified holds a strong reference; Schedule::schedule(Notified)
// hands ownership of that reference to the run queue, and the consumer that
// pops the queue gets the strong ref back to drive the next poll round.

mem Notified {
    raw    // RawTask*
}

// from_raw(raw): wrap a RawTask pointer.
//   Caller must guarantee the strong ref count covers this Notified slot.
fn notified_from_raw(raw) Notified {
    n<Notified> = new Notified
    n.raw = raw
    return n
}

// Notified::raw(): unwrap to the underlying RawTask*
Notified::raw() {
    return this.raw
}
