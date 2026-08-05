// Leaf future yielding the spawned task's output. consumed is monotonic so
// repeat polls return AlreadyConsumed instead of tripping futuredone().

use runtime

// Async leaf future; State.JOIN_WAKER + Cell.waker_slot_packed track the waker.
mem JoinHandle: async {
    RawTask* task_ptr    // null when the task has been released
    i32 consumed    // monotonic 0->1 once the value is taken
}

// Initialise a JoinHandle around raw.
JoinHandle::init(raw<RawTask>){
    this.task_ptr = raw
    this.consumed = 0
}

// Detach without awaiting (mother JoinHandle::drop). Required: Tu has no
// automatic Drop, so fire-and-forget spawn must call this or task refs leak.
JoinHandle::detach(){
    rtask<RawTask> = this.task_ptr
    if rtask == null {
        return
    }
    this.task_ptr = null
    // Fast path: still at INITIAL (not yet polled) — mother drop_join_handle_fast.
    life_st<TaskState> = rtask.life_st()
    if life_st.drop_join_handle_fast() == 1 {
        return
    }
    rtask.drop_join_handle_slow()
}

// Cancel the underlying task (idempotent). Join then yields JoinErrorCancelled.
JoinHandle::abort(){
    rtask<RawTask> = this.task_ptr
    if rtask == null { return }
    rtask.abort_signal()
}

// AbortHandle view of the same RawTask (safe after this JoinHandle is dropped).
JoinHandle::abort_handle() AbortHandle {
    return AbortHandle::new(this.task_ptr)
}

// Poll the JoinHandle.
// Register waker then re-check COMPLETE to close the register-vs-complete race.
// set_join_waker fails when COMPLETE — fall through and take the output.
JoinHandle::poll(ctx){
    if this.task_ptr == null {
        return runtime.PollReady, JoinErrorAlreadyConsumed
    }
    if this.consumed == 1 {
        return runtime.PollReady, JoinErrorAlreadyConsumed
    }
    rtask<RawTask> = this.task_ptr
    snap<i32> = rtask.life_load()

    if (snap & COMPLETE) == 0 {
        packed<u64> = resolve_poll_ctx(ctx.(u64))
        arm<i32> = rtask.register_join_waker(packed)
        snap = rtask.life_load()
        if arm == 0 && (snap & COMPLETE) == 0 {
            return runtime.PollPending
        }
    }

    err<i32> = 0
    val<i64> = 0
    err, val = rtask.read_output()
    this.consumed = 1
    if err == 0 {
        return runtime.PollReady, val
    }
    return runtime.PollReady, err
}
