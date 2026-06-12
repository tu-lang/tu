// Thin RawTask wrapper carrying a strong ref. Schedulers move tasks around
// the run queue as Notified values; popping the queue transfers the ref back.

// One-field wrapper so schedulers do not depend on RawTask layout.
mem Notified {
    RawTask* raw
}

// Wrap a RawTask*. Caller must guarantee the strong ref count covers this slot.
fn notified_from_raw(raw<RawTask>) Notified {
    n<Notified> = new Notified
    n.raw = raw
    return n
}

// Unwrap to the underlying RawTask*.
Notified::raw() RawTask* {
    return this.raw
}

