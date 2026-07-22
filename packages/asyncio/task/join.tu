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

// Poll the JoinHandle.
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
        // Register the harness-published task waker (ctx arg is null-padded
        // by the dynstackcall poll path), then re-check COMPLETE to close
        // the register-vs-complete race (mother JOIN_WAKER protocol).
        packed<u64> = resolve_poll_ctx(ctx.(u64))
        rtask.register_join_waker(packed)
        snap = rtask.life_load()
        if (snap & COMPLETE) == 0 {
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
