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
    u32 state         // atomic
    u32 num_workers
}

// Sleepers buffer protected by MtSynced.lock. capacity = num_workers.
mem IdleSynced {
    u32* sleepers     // worker indices currently parked
    u32  sleepers_len
    u32  sleepers_cap
}

// Build paired (Idle, IdleSynced) for a runtime with `num` workers.
const idle_new(num<u32>) (Idle, IdleSynced) {
    i<Idle> = new Idle
    i.state       = num << UNPARK_SHIFT       // all unparked, none searching
    i.num_workers = num

    s<IdleSynced> = new IdleSynced
    s.sleepers     = std.malloc(sizeof(u32) * num.(u64))
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
Idle::transition_worker_to_searching() bool {
    addr<u32*> = &this.state
    loop {
        cur<u32> = atomic.load(addr)
        unparked<u32>  = idle_state_unparked(cur)
        searching<u32> = idle_state_searching(cur)
        if searching * 2 >= unparked return false
        new_state<u32> = idle_state_pack(unparked, searching + 1)
        if atomic.cas(addr.(i32*), cur.(i32), new_state.(i32)) != 0 return true
    }
    return false
}

// Returns true when this is the last searching worker (caller should
// notify_one to keep the pipeline filled).
Idle::transition_worker_from_searching() bool {
    addr<u32*> = &this.state
    loop {
        cur<u32> = atomic.load(addr)
        unparked<u32>  = idle_state_unparked(cur)
        searching<u32> = idle_state_searching(cur)
        if searching == 0 return false
        new_state<u32> = idle_state_pack(unparked, searching - 1)
        if atomic.cas(addr.(i32*), cur.(i32), new_state.(i32)) != 0 {
            if searching == 1 return true
            return false
        }
    }
    return false
}

// Move the worker out of unparked. is_searching tells us whether the
// caller was the last searcher; if not we refuse to park (caller
// continues spinning) so we don't lose work-stealing momentum.
Idle::transition_worker_to_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>, is_searching<bool>) bool {
    if is_searching == false return false
    addr<u32*> = &this.state
    loop {
        cur<u32> = atomic.load(addr)
        unparked<u32>  = idle_state_unparked(cur)
        searching<u32> = idle_state_searching(cur)
        if unparked == 0 return false
        new_unparked<u32> = unparked - 1
        new_searching<u32> = searching
        if searching > 0 new_searching = searching - 1
        new_state<u32> = idle_state_pack(new_unparked, new_searching)
        if atomic.cas(addr.(i32*), cur.(i32), new_state.(i32)) != 0 break
    }

    lock.lock()
    if synced.sleepers_len < synced.sleepers_cap {
        synced.sleepers[synced.sleepers_len] = worker
        synced.sleepers_len += 1
    }
    lock.unlock()
    return true
}

// Worker just woke — update unparked counter and remove from sleepers.
Idle::transition_worker_from_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>){
    addr<u32*> = &this.state
    loop {
        cur<u32> = atomic.load(addr)
        unparked<u32>  = idle_state_unparked(cur)
        searching<u32> = idle_state_searching(cur)
        new_state<u32> = idle_state_pack(unparked + 1, searching)
        if atomic.cas(addr.(i32*), cur.(i32), new_state.(i32)) != 0 break
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
    if this.notify_should_wakeup() == false return 0, 0
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
Idle::notify_should_wakeup() bool {
    cur<u32> = atomic.load(&this.state)
    unparked<u32>  = idle_state_unparked(cur)
    searching<u32> = idle_state_searching(cur)
    if searching > 0 return false
    if unparked >= this.num_workers return false
    return true
}

// Wrapper that picks a sleeper and tells the caller to wake them. Caller
// is responsible for the actual unpark (we don't hold a Parker* here).
Idle::notify_one(synced<IdleSynced>, lock<runtime.MutexInter>) (i32, u32) {
    return this.worker_to_notify(synced, lock)
}

