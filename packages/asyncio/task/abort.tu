// Idempotent task cancellation handle. Multiple abort() calls are safe; only
// the first one actually pokes the scheduler.

// Wraps a RawTask* so user code can cancel without holding the JoinHandle.
mem AbortHandle {
    RawTask* task_ptr    // null after the task has been released
}

// Build a handle for raw.
const AbortHandle::new(raw<RawTask>) AbortHandle {
    ah<AbortHandle> = new AbortHandle
    ah.task_ptr = raw
    return ah
}

// Set CANCELLED (monotonic) and ensure exactly one schedule kick fires.
AbortHandle::abort(){
    rtask<RawTask> = this.task_ptr
    if rtask == null { return }
    rtask.abort_signal()
}
