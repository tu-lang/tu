// Thread-local park used during runtime construction. CachedParkThread
// wraps library runtime.Note so the current_thread block_on path can park
// while waiting for cross-thread schedule notifications.

use std.atomic
use sys
use asyncio.runtime.blocking as rtblk

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS_OK<i64> = 1

EMPTY_PARK<i32>    = 0
PARKED_PARK<i32>   = 1
NOTIFIED_PARK<i32> = 2

// Per-thread park slot. park_state is the design's `state` (Tu rename: `state`
// collides with typeassert / mem State). note_bits is Note* raw bits.
mem CachedParkThread {
    i32  park_state // atomic
    u64  note_bits
}

// Build a CachedParkThread.
const CachedParkThread::new() CachedParkThread {
    p<CachedParkThread> = new CachedParkThread
    p.park_state = EMPTY_PARK
    p.note_bits = rtblk.librt_note_new_raw()
    return p
}

// Block until somebody calls unpark.
CachedParkThread::wait_until_wake(){
    addr<i32*> = &this.park_state
    if atomic.cas(addr, NOTIFIED_PARK, EMPTY_PARK) == CAS_OK { return }
    if atomic.cas(addr, EMPTY_PARK, PARKED_PARK) != CAS_OK { return }
    rtblk.librt_note_sleep_raw(this.note_bits)
    rtblk.librt_note_clear_raw(this.note_bits)
    atomic.cas(addr, PARKED_PARK, EMPTY_PARK)
    atomic.cas(addr, NOTIFIED_PARK, EMPTY_PARK)
}

// Park up to `d`. First-pass forwards to plain park; the IO/time driver
// integration in build_* will replace this with a driver.park_timeout.
CachedParkThread::park_timeout(d<sys.Duration>){
    this.wait_until_wake()
}

// Wake the parker. Idempotent.
CachedParkThread::unpark(){
    addr<i32*> = &this.park_state
    if atomic.cas(addr, EMPTY_PARK, NOTIFIED_PARK) == CAS_OK { return }
    if atomic.cas(addr, PARKED_PARK, NOTIFIED_PARK) == CAS_OK {
        rtblk.librt_note_wake_raw(this.note_bits)
    }
}
