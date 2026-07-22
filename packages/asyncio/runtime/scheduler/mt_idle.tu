// Tracks how many workers are searching vs parked. The owner-side state
// packs both counts into a single u32 so transition_to_searching /
// from_searching can move atomically; sleepers is a side list under
// MtSynced.lock used to hand a sleeping worker an unpark token.

use std.atomic
use runtime
use std

// state layout: [unparked:u16 << 16 | searching:u16].
UNPARK_SHIFT<u32> = 16
SEARCH_MASK<u32>  = 0xFFFF

// Worker bookkeeping snapshot.
mem Idle {
    i32 state         // atomic; packed unparked/searching counts
    u32 num_workers
}

// Sleepers buffer protected by MtSynced.lock. capacity = num_workers.
mem IdleSynced {
    u32* sleepers     // worker indices currently parked
    u32  sleepers_len
    u32  sleepers_cap
}

// Build paired (Idle, IdleSynced) for a runtime with `num` workers.
fn idle_new(num<u32>) (Idle, IdleSynced) {
    i<Idle> = new Idle
    i.state       = num << UNPARK_SHIFT       // all unparked, none searching
    i.num_workers = num

    s<IdleSynced> = new IdleSynced
    nc<u64> = num.(u64)
    s.sleepers     = std.malloc(4 * nc)
    s.sleepers_len = 0
    s.sleepers_cap = num
    return i, s
}

// Helpers over the packed state.
fn idle_state_unparked(s<u32>) u32 {
    return (s >> UNPARK_SHIFT) & 0xFFFF
}
fn idle_state_searching(s<u32>) u32 {
    return s & SEARCH_MASK
}
fn idle_state_pack(unparked<u32>, searching<u32>) u32 {
    return (unparked << UNPARK_SHIFT) | (searching & SEARCH_MASK)
}

// Returns true on the unparked->searching transition; false when at
// most half of the workers are unparked (we cap concurrent searchers at
// num_workers/2 to avoid thundering-herd steal).
Idle::transition_worker_to_searching() i32 {
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        if searching * 2 >= unparked return 0
        packed<u32> = idle_state_pack(unparked, searching + 1)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK return 1
    }
    return 0
}

// Returns 1 when this is the last searching worker (caller should
// notify_one to keep the pipeline filled).
Idle::transition_worker_from_searching() i32 {
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        if searching == 0 return 0
        packed<u32> = idle_state_pack(unparked, searching - 1)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK {
            if searching == 1 return 1
            return 0
        }
    }
    return 0
}

// Move the worker out of unparked. is_searching tells us whether the
// caller was the last searcher; if not we refuse to park (caller
// continues spinning) so we don't lose work-stealing momentum.
Idle::transition_worker_to_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>, is_searching<i32>) i32 {
    if is_searching == 0 return 0
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        if unparked == 0 return 0
        new_unparked<u32> = unparked - 1
        new_searching<u32> = searching
        if searching > 0 new_searching = searching - 1
        packed<u32> = idle_state_pack(new_unparked, new_searching)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK break
    }

    lock.lock()
    if synced.sleepers_len < synced.sleepers_cap {
        synced.sleepers[synced.sleepers_len] = worker
        synced.sleepers_len += 1
    }
    lock.unlock()
    return 1
}

// Worker just woke — update unparked counter and remove from sleepers.
Idle::transition_worker_from_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>){
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        packed<u32> = idle_state_pack(unparked + 1, searching)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK break
    }

    lock.lock()
    // Compact the sleepers array by removing `worker`.
    n<u32> = synced.sleepers_len
    for i<u32> = 0 ; i < n ; i += 1 {
        if synced.sleepers[i] == worker {
            for j<u32> = i ; j < n - 1 ; j += 1 {
                synced.sleepers[j] = synced.sleepers[j + 1]
            }
            synced.sleepers_len -= 1
            break
        }
    }
    lock.unlock()
}

// Pick one sleeper to wake; returns (1, idx) on hit, (0, 0) when empty.
Idle::worker_to_notify(synced<IdleSynced>, lock<runtime.MutexInter>) (i32, u32) {
    if this.notify_should_wakeup() == 0 return 0, 0
    lock.lock()
    if synced.sleepers_len == 0 {
        lock.unlock()
        return 0, 0
    }
    synced.sleepers_len -= 1
    idx<u32> = synced.sleepers[synced.sleepers_len]
    lock.unlock()
    return 1, idx
}

// True when we should wake another worker (no current searcher and at
// least one parked worker).
Idle::notify_should_wakeup() i32 {
    cur<i32> = this.state
    unparked<u32>  = idle_state_unparked(cur.(u32))
    searching<u32> = idle_state_searching(cur.(u32))
    if searching > 0 return 0
    if unparked >= this.num_workers return 0
    return 1
}

// Wrapper that picks a sleeper and tells the caller to wake them. Caller
// is responsible for the actual unpark (we don't hold a Parker* here).
Idle::notify_one(synced<IdleSynced>, lock<runtime.MutexInter>) (i32, u32) {
    hit<i32> = 0
    idx<u32> = 0
    hit, idx = this.worker_to_notify(synced, lock)
    return hit, idx
}

