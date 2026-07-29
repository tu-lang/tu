// Worker park / unpark. State names match mother park.rs
// (EMPTY / PARKED_CONDVAR / PARKED_DRIVER / NOTIFIED).
// PARKED_DRIVER + driver.park is wired via ParkDriverHub but currently
// disabled: concurrent enable_all MT runs SEGV'd in epoll/futex paths.
// Parkers fall back to osyield polling (PARKED_CONDVAR) until driver
// multi-thread park is hardened. Hub + ioh wake stay for the next pass.

use runtime
use std.atomic
use sys
use asyncio.runtime.io as rtio

EMPTY<i32>           = 0
PARKED_CONDVAR<i32>  = 1
PARKED_DRIVER<i32>   = 2
NOTIFIED<i32>        = 3

// Shared across all workers' Parkers (mother Arc<Shared> + TryLock<Driver>).
mem ParkDriverHub {
    u64 drv_bits
    u64 handle_bits
    u64 ioh_bits
    i32 lock_held               // reserved for PARKED_DRIVER try-lock
}

mem Parker {
    i32            state
    runtime.Note   park_note
    ParkDriverHub* hub
}

mem Unparker {
    Parker* owner
}

const ParkDriverHub::new(drv_bits<u64>, handle_bits<u64>, ioh_bits<u64>) ParkDriverHub {
    h<ParkDriverHub> = new ParkDriverHub
    h.drv_bits = drv_bits
    h.handle_bits = handle_bits
    h.ioh_bits = ioh_bits
    h.lock_held = 0
    return h
}

const Parker::new(hub<ParkDriverHub>) Parker {
    p<Parker> = new Parker
    p.state = EMPTY
    p.park_note.Clear()
    p.hub = hub
    return p
}

const Unparker::new(p<Parker>) Unparker {
    u<Unparker> = new Unparker
    u.owner = p
    return u
}

// Park until unpark. osyield poll only (see file header).
Parker::wait_until_wake(handle_ptr<u64>) i32 {
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
        return 0
    }

    if atomic.cas(addr, EMPTY, PARKED_CONDVAR) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
        return 0
    }

    loop {
        if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
            return 0
        }
        cur<i32> = *addr
        if cur != PARKED_CONDVAR {
            atomic.cas(addr, PARKED_CONDVAR, EMPTY)
            atomic.cas(addr, NOTIFIED, EMPTY)
            return 0
        }
        runtime.osyield()
    }
    return 0
}

Parker::park_timeout(handle_ptr<u64>, max<sys.Duration>) i32 {
    return this.wait_until_wake(handle_ptr)
}

Unparker::unpark(){
    p<Parker> = this.owner
    addr<i32*> = &p.state
    old<i32> = atomic.xchg(addr, NOTIFIED)
    // When PARKED_DRIVER is re-enabled, kick eventfd here (mother unpark).
    if old == PARKED_DRIVER {
        hub<ParkDriverHub> = p.hub
        if hub != null && hub.ioh_bits != 0 {
            rtio.io_handle_wake_bits(hub.ioh_bits)
        }
    }
}

Parker::shutdown(handle_ptr<u64>){
    u<Unparker> = Unparker::new(this)
    u.unpark()
    this.hub = null
}
