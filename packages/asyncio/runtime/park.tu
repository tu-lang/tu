// Thread-local park used during runtime construction. CachedParkThread
// wraps runtime.Note so the current_thread block_on path can park while
// waiting for cross-thread schedule notifications.

use runtime as rtcore
use std.atomic
use sys

EMPTY_PARK<i32>   = 0
PARKED_PARK<i32>  = 1
NOTIFIED_PARK<i32> = 2

// Per-thread park slot.
mem CachedParkThread {
    i32          state    // atomic
    rtcore.Note note
}

// Build a CachedParkThread.
const CachedParkThread::new() CachedParkThread {
    p<CachedParkThread> = new CachedParkThread
    p.state = EMPTY_PARK
    p.note.Clear()
    return p
}

// Block until somebody calls unpark.
CachedParkThread::park(){
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED_PARK, EMPTY_PARK) != 0 return
    if atomic.cas(addr, EMPTY_PARK, PARKED_PARK) == 0 return
    this.note.Sleep()
    this.note.Clear()
    atomic.cas(addr, PARKED_PARK, EMPTY_PARK)
    atomic.cas(addr, NOTIFIED_PARK, EMPTY_PARK)
}

// Park up to `d`. First-pass forwards to plain park; the IO/time driver
// integration in build_* will replace this with a driver.park_timeout.
CachedParkThread::park_timeout(d<sys.Duration>){
    this.park()
}

// Wake the parker. Idempotent.
CachedParkThread::unpark(){
    addr<i32*> = &this.state
    if atomic.cas(addr, EMPTY_PARK, NOTIFIED_PARK) != 0 return
    if atomic.cas(addr, PARKED_PARK, NOTIFIED_PARK) != 0 {
        this.note.Wake()
    }
}

