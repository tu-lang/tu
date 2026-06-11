// Idempotent task cancellation handle. Multiple abort() calls are safe; only
// the first one actually pokes the scheduler.

// Wraps a RawTask* so user code can cancel without holding the JoinHandle.
mem AbortHandle {
    raw   // RawTask*, may be null after the task has been released
}

// Build a handle for raw.
const AbortHandle::new(raw) AbortHandle {
    h<AbortHandle> = new AbortHandle
    h.raw = raw
    return h
}

// Set CANCELLED (monotonic) and ensure exactly one schedule kick fires.
// by_ref does not consume a refcount; the existing run-queue ref handles it.
AbortHandle::abort(){
    raw = this.raw
    if raw == null return
    h<Header> = raw.hdr
    st<State> = h.state
    st.set_cancelled()

    code<i32> = st.transition_to_notified_by_ref()
    if code == TN_Submit {
        sched = h.scheduler
        if sched != null {
            n<Notified> = notified_from_raw(raw)
            sched.schedule(n)
        }
    }
}
