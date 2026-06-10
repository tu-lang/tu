// AbortHandle: cancel a spawned task without waiting on it
// Related: packages-asyncio-runtime task 3.29, R8.4, R9.5
//
// abort() is idempotent.  The first call sets the CANCELLED bit on the
// task's State and tries to flip NOTIFIED so the scheduler picks the task
// up and runs the harness cancel path.  Subsequent calls just no-op (the
// CANCELLED bit is monotonic).

mem AbortHandle {
    raw   // RawTask*
}

const AbortHandle::new(raw) AbortHandle {
    h<AbortHandle> = new AbortHandle
    h.raw = raw
    return h
}

// abort(): mark the task as cancelled and ensure exactly one schedule kick
// fires through the scheduler.
AbortHandle::abort(){
    raw = this.raw
    if raw == null return
    h<Header> = raw.hdr
    st<State> = h.state
    st.set_cancelled()

    // Try to flip the task into NOTIFIED so the scheduler reruns the harness.
    // by_ref does NOT consume a refcount; it relies on the scheduler queue's
    // own strong ref.  We only need to schedule on the Submit branch, the
    // existing run-queue entry already covers DoNothing.
    code<i32> = st.transition_to_notified_by_ref()
    if code == TN_Submit {
        sched = h.scheduler
        if sched != null {
            n<Notified> = notified_from_raw(raw)
            sched.schedule(n)
        }
    }
}
