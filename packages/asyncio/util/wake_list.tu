// WakeList: small array that batches ctx values before waking them all
// Related: packages-asyncio-runtime task 2.17, R33.4, R33.5, R33.6
// Design: design §17.2 (mirrors sync.wake_list; this copy stays here for
// scheduler-internal batched wakeups)
//
// Use case: sync.Notify::notify_waiters / Semaphore::release(N) need to
// collect ctx values while holding a lock, drop the lock, and only then
// invoke the scheduler's schedule.  NUM_WAKERS=32 matches the tokio batch
// limit; once full, callers should drop the lock, wake_all, then reacquire
// the lock and continue.
//
// Phase 1 only exposes wake_all_with(closure) -- a closure-driven hook the
// caller defines.  Once packages/asyncio/runtime/scheduler ships its
// SchedulerHandle api (task 4.10+) we will add wake_all_via_handle(sched)
// that goes through Schedule::schedule.

NUM_WAKERS<i32> = 32

mem WakeList {
    u64 ctxs[32]   // length must match NUM_WAKERS (mem array length must be a literal)
    i32 len
}

WakeList::init(){
    this.len = 0
}

// is_empty(): no ctx collected yet
WakeList::is_empty() bool {
    if this.len == 0 return true
    return false
}

// is_full(): hit the NUM_WAKERS upper bound
WakeList::is_full() bool {
    if this.len >= NUM_WAKERS return true
    return false
}

// push(ctx): append ctx to the pending array; returns false when already
// full (the caller must wake_all and try again).
WakeList::push(ctx<u64>) bool {
    if this.len >= NUM_WAKERS return false
    this.ctxs[this.len] = ctx
    this.len += 1
    return true
}

// len_count(): current number of collected ctx values; aliased to avoid
// shadowing std.len
WakeList::len_count() i32 {
    return this.len
}

// wake_all_with(closure): call closure(ctx) for every collected entry, then
// reset the buffer.  Must NOT be invoked while holding any lock.
//   closure has signature fn(ctx<u64>) {} or func(ctx) {}; a typical impl
//   unpacks ctx into (sched, task_id) and asks the scheduler to push the
//   matching task back onto the run queue.
WakeList::wake_all_with(closure){
    for i<i32> = 0 ; i < this.len ; i += 1 {
        c<u64> = this.ctxs[i]
        closure(c)
    }
    this.len = 0
}
