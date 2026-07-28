// Worker park / unpark. Three states (EMPTY/PARKED/NOTIFIED).
// wait_until_wake yield-polls NOTIFIED — Note::Sleep over clone() worker
// threads has hit futex SEGV; driver park_timeout still TODO.

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

// Park indefinitely. Yield-poll on NOTIFIED to avoid Note/futex races
// across clone() worker threads (Note::Sleep has SEGV under N workers).
Parker::wait_until_wake(handle_ptr<u64>) i32 {
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK return 0

    if atomic.cas(addr, EMPTY, PARKED) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
        return 0
    }

    loop {
        if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
            atomic.cas(addr, PARKED, EMPTY)
            return 0
        }
        cur<i32> = *addr
        if cur != PARKED {
            atomic.cas(addr, PARKED, EMPTY)
            atomic.cas(addr, NOTIFIED, EMPTY)
            return 0
        }
        runtime.osyield()
    }
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

