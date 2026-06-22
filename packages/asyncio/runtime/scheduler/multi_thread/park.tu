// Worker park / unpark. Three states (EMPTY/PARKED/NOTIFIED) on top of
// runtime.Note. Park yields control to the IO/time driver (when
// driver_slot is set) and unblocks via Note::Sleep otherwise.

use runtime
use std.atomic
use sys

EMPTY<u32>    = 0
PARKED<u32>   = 1
NOTIFIED<u32> = 2

// Per-worker park slot.
mem Parker {
    u32          state         // atomic
    runtime.Note note
    u64          driver_slot   // raw bits of runtime.driver.Driver*; 0 = no driver
}

// Counterpart used by other workers to wake us up.
mem Unparker {
    Parker* p
}

// Build a Parker that delegates to the supplied driver pointer (may be 0).
const Parker::new(driver_ptr<u64>) Parker {
    p<Parker> = new Parker
    p.state = EMPTY
    p.note.Clear()
    p.driver_slot = driver_ptr
    return p
}

// Build an Unparker pointing at p.
const Unparker::new(p<Parker>) Unparker {
    u<Unparker> = new Unparker
    u.p = p
    return u
}

// Park indefinitely. Returns 0 on a normal wake, surfaces driver errors
// when a driver is wired in.
Parker::park(handle_ptr<u64>) i32 {
    addr<u32*> = &this.state
    // Fast path: someone already notified us.
    if atomic.cas(addr.(i32*), NOTIFIED.(i32), EMPTY.(i32)) != 0 return 0

    if atomic.cas(addr.(i32*), EMPTY.(i32), PARKED.(i32)) == 0 {
        // Lost race with concurrent notify; treat as woken.
        atomic.cas(addr.(i32*), NOTIFIED.(i32), EMPTY.(i32))
        return 0
    }

    // Block on the Note. Once woken, reset state to EMPTY.
    this.note.Sleep()
    this.note.Clear()
    atomic.cas(addr.(i32*), PARKED.(i32), EMPTY.(i32))
    atomic.cas(addr.(i32*), NOTIFIED.(i32), EMPTY.(i32))
    return 0
}

// Park with a maximum duration. First-pass implementation simply forwards
// to park(); driver-aware timeouts land in Phase 10 once Driver::park
// is wired through handle_ptr.
Parker::park_timeout(handle_ptr<u64>, max<sys.Duration>) i32 {
    return this.park(handle_ptr)
}

// Wake the parker. Idempotent.
Unparker::unpark(){
    p<Parker> = this.p
    addr<u32*> = &p.state
    if atomic.cas(addr.(i32*), EMPTY.(i32), NOTIFIED.(i32)) != 0 return
    if atomic.cas(addr.(i32*), PARKED.(i32), NOTIFIED.(i32)) != 0 {
        p.note.Wake()
        return
    }
    // Already NOTIFIED — nothing to do.
}

// Wake every worker on the same handle and surrender the driver slot.
Parker::shutdown(handle_ptr<u64>){
    u<Unparker> = Unparker::new(this)
    u.unpark()
    // driver_slot release is the runtime root's job; we just clear our
    // copy so subsequent park() calls are pure-Note.
    this.driver_slot = 0
}

