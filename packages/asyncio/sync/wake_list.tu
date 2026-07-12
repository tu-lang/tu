// Small array buffer used to batch ctx values for later wake-up.
// User-facing variant alongside util.wake_list; kept in sync because the
// scheduler glue layer will dispatch through this from sync primitives.

NUM_WAKERS<i32> = 32

// Fixed-size scratch buffer of u64 ctx values.
mem WakeList {
    u64 ctxs[32]    // length must equal NUM_WAKERS
    i32 len
}

// Reset to empty.
WakeList::init(){
    this.len = 0
}

WakeList::is_empty() i32 {
    if this.len == 0 return 1
    return 0
}

WakeList::is_full() i32 {
    if this.len >= NUM_WAKERS return 1
    return 0
}

// Append ctx; returns 0 when buffer is already full so the caller can
// drop the lock, drain, and try again.
WakeList::push(ctx<u64>) i32 {
    if this.len >= NUM_WAKERS return 0
    this.ctxs[this.len] = ctx
    this.len += 1
    return 1
}

// Aliased to avoid shadowing std.len when used inline.
WakeList::len_count() i32 {
    return this.len
}

// Hand each ctx to sched.schedule() one by one and reset. Must NOT be
// invoked while holding the parent lock to avoid waker re-entry deadlocks.
WakeList::wake_all(sched){
    for i<i32> = 0 ; i < this.len ; i += 1 {
        c<u64> = this.ctxs[i]
        if sched != null {
            sched.schedule(c)
        }
    }
    this.len = 0
}

