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
    // Worker indices only (not GC pointers); noscan=1.
    s.sleepers     = runtime.malloc(4 * nc, 1.(i8), 1.(i8))
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

// Mother State::unpark_one: +1 unparked and +num_searching searching.
fn idle_unpark_one(addr<i32*>, num_searching<u32>) {
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        packed<u32> = idle_state_pack(unparked + 1, searching + num_searching)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK return
    }
}

// Returns true on the unparked->searching transition; false when at
// most half of the workers are already searching (mother: 2*searching >= num_workers).
Idle::transition_worker_to_searching() i32 {
    addr<i32*> = &this.state
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        if searching * 2 >= this.num_workers return 0
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

// Move the worker into parked: push onto sleepers and decrement unparked.
// is_searching: whether this worker was searching (also dec searching count).
// Returns 1 when this was the last searcher — caller must notify_if_work_pending.
//
// Mother idle.rs: take synced lock FIRST, then dec state, then push sleepers.
// Updating state before the sleeper list opens a window where notify sees
// searching==0 / unparked<n but sleepers empty → miss, then the worker
// sleeps forever with inject work stranded.
Idle::transition_worker_to_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>, is_searching<i32>) i32 {
    addr<i32*> = &this.state
    last_searcher<i32> = 0
    lock.lock()
    loop {
        cur<i32> = *addr
        unparked<u32>  = idle_state_unparked(cur.(u32))
        searching<u32> = idle_state_searching(cur.(u32))
        new_unparked<u32> = unparked
        if unparked > 0 {
            new_unparked = unparked - 1
        }
        new_searching<u32> = searching
        if is_searching == 1 && searching > 0 {
            new_searching = searching - 1
            if searching == 1 {
                last_searcher = 1
            }
        }
        packed<u32> = idle_state_pack(new_unparked, new_searching)
        new_state<i32> = packed.(i32)
        if atomic.cas(addr, cur, new_state) == CAS_OK break
    }
    if synced.sleepers_len < synced.sleepers_cap {
        synced.sleepers[synced.sleepers_len] = worker
        synced.sleepers_len += 1
    }
    lock.unlock()
    return last_searcher
}

// Worker just woke — update unparked counter and remove from sleepers.
Idle::transition_worker_from_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>){
    this.unpark_worker_by_id(synced, lock, worker)
}

// Pick one sleeper to wake; returns (1, idx) on hit, (0, 0) when empty.
// Mother: only when notify_should_wakeup (no searcher).
Idle::worker_to_notify(synced<IdleSynced>, lock<runtime.MutexInter>) (i32, u32) {
    if this.notify_should_wakeup() == 0 return 0, 0
    lock.lock()
    // Re-check under lock (mother).
    if this.notify_should_wakeup() == 0 {
        lock.unlock()
        return 0, 0
    }
    if synced.sleepers_len == 0 {
        lock.unlock()
        return 0, 0
    }
    // Notify path accounts for wake-up state here; woken worker should not
    // blindly +unparked on return from park.
    idle_unpark_one(&this.state, 1)
    synced.sleepers_len -= 1
    idx<u32> = synced.sleepers[synced.sleepers_len]
    lock.unlock()
    return 1, idx
}

// Remove worker from sleepers and +1 unparked (searching unchanged).
// Returns 1 when worker was parked.
Idle::unpark_worker_by_id(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>) i32 {
    lock.lock()
    n<u32> = synced.sleepers_len
    for i<u32> = 0 ; i < n ; i += 1 {
        if synced.sleepers[i] == worker {
            for j<u32> = i ; j < n - 1 ; j += 1 {
                synced.sleepers[j] = synced.sleepers[j + 1]
            }
            synced.sleepers_len -= 1
            idle_unpark_one(&this.state, 0)
            lock.unlock()
            return 1
        }
    }
    lock.unlock()
    return 0
}

// True while worker index is still in sleepers list.
Idle::is_parked(synced<IdleSynced>, lock<runtime.MutexInter>, worker<u32>) i32 {
    lock.lock()
    n<u32> = synced.sleepers_len
    for i<u32> = 0 ; i < n ; i += 1 {
        if synced.sleepers[i] == worker {
            lock.unlock()
            return 1
        }
    }
    lock.unlock()
    return 0
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

// Clear idle searching credits that no live WorkerCore claims (SEARCHING_LEAK).
// Call when notify misses so inject/LIFO work is not stranded while every
// worker sleeps on condvar (eventfd only wakes PARKED_DRIVER).
fn mt_heal_searching_leak(shared<MtShared>) {
    if shared == null || shared.idle == null {
        return
    }
    cur<i32> = shared.idle.state
    searching<u32> = idle_state_searching(cur.(u32))
    if searching == 0 {
        return
    }
    any<i32> = 0
    i<u32> = 0
    while i < shared.num_workers {
        bits<u64> = shared.remotes[i]
        if bits != 0 {
            r<Remote> = bits.(Remote)
            if r.core_bits != 0 {
                c<WorkerCore> = r.core_bits.(WorkerCore)
                if c.is_searching == 1 {
                    any = 1
                    break
                }
            }
        }
        i += 1
    }
    if any == 1 {
        return
    }
    // Drop leaked credits one-by-one.
    n<u32> = searching
    while n > 0 {
        shared.idle.transition_worker_from_searching()
        n -= 1
    }
}


// Wrapper that picks a sleeper and tells the caller to wake them. Caller
// is responsible for the actual unpark (we don't hold a Parker* here).
Idle::notify_one(synced<IdleSynced>, lock<runtime.MutexInter>) (i32, u32) {
    hit<i32> = 0
    idx<u32> = 0
    hit, idx = this.worker_to_notify(synced, lock)
    return hit, idx
}

