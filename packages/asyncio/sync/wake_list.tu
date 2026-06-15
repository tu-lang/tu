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

WakeList::is_empty() bool {
    if this.len == 0 return true
    return false
}

WakeList::is_full() bool {
    if this.len >= NUM_WAKERS return true
    return false
}

// Append ctx; returns false when buffer is already full so the caller can
// drop the lock, drain, and try again.
WakeList::push(ctx<u64>) bool {
    if this.len >= NUM_WAKERS return false
    this.ctxs[this.len] = ctx
    this.len += 1
    return true
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

