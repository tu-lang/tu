// Worker park / unpark. Three states (EMPTY/PARKED/NOTIFIED) on top of
// runtime.Note. Park yields control to the IO/time driver (when
// driver_slot is set) and unblocks via Note::Sleep otherwise.

use runtime
use std.atomic
use sys

EMPTY<i32>    = 0
PARKED<i32>   = 1
NOTIFIED<i32> = 2

// Per-worker park slot.
mem Parker {
    i32          state         // atomic
    runtime.Note park_note
    u64          driver_slot   // raw bits of runtime.driver.Driver*; 0 = no driver
}

// Counterpart used by other workers to wake us up.
mem Unparker {
    Parker* owner
}

// Build a Parker that delegates to the supplied driver pointer (may be 0).
const Parker::new(driver_ptr<u64>) Parker {
    p<Parker> = new Parker
    p.state = EMPTY
    p.park_note.Clear()
    p.driver_slot = driver_ptr
    return p
}

// Build an Unparker pointing at p.
const Unparker::new(p<Parker>) Unparker {
    u<Unparker> = new Unparker
    u.owner = p
    return u
}

// Park indefinitely. Returns 0 on a normal wake, surfaces driver errors
// when a driver is wired in.
Parker::wait_until_wake(handle_ptr<u64>) i32 {
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK return 0

    if atomic.cas(addr, EMPTY, PARKED) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
        return 0
    }

    this.park_note.Sleep()
    this.park_note.Clear()
    atomic.cas(addr, PARKED, EMPTY)
    atomic.cas(addr, NOTIFIED, EMPTY)
    return 0
}

// Park with a maximum duration. First-pass implementation simply forwards
// to park(); driver-aware timeouts land in Phase 10 once Driver::park
// is wired through handle_ptr.
Parker::park_timeout(handle_ptr<u64>, max<sys.Duration>) i32 {
    return this.wait_until_wake(handle_ptr)
}

// Wake the parker. Idempotent.
Unparker::unpark(){
    p<Parker> = this.owner
    addr<i32*> = &p.state
    if atomic.cas(addr, EMPTY, NOTIFIED) == CAS_OK { return }
    if atomic.cas(addr, PARKED, NOTIFIED) == CAS_OK {
        p.park_note.Wake()
        return
    }
}

// Wake every worker on the same handle and surrender the driver slot.
Parker::shutdown(handle_ptr<u64>){
    u<Unparker> = Unparker::new(this)
    u.unpark()
    // driver_slot release is the runtime root's job; we just clear our
    // copy so subsequent park() calls are pure-Note.
    this.driver_slot = 0
}

