// Small array buffer used to batch ctx values for later wake-up.
// NUM_WAKERS=32 matches the batch limit; on overflow callers should
// drop the lock, wake_all, then continue collecting under the lock again.

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

// Append ctx; returns 0 when buffer is already full.
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

// Drop pending wakes without scheduling.
fn wake_list_clear(list<WakeList>) {
    list.len = 0
}

// Call closure(ctx) for every entry, then reset. Must NOT be invoked while
// holding any lock to avoid waker re-entry deadlocks.
WakeList::wake_all_with(closure){
    for i<i32> = 0 ; i < this.len ; i += 1 {
        c<u64> = this.ctxs[i]
        closure(c)
    }
    this.len = 0
}
