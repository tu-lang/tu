// Worker park / unpark. State machine matches mother park.rs
// (EMPTY / PARKED_CONDVAR / PARKED_DRIVER / NOTIFIED).
//
// Holds TryLock for the whole park_timeout so only one worker drives
// IoDriver::turn / TimeDriver::park_internal at a time.

use runtime
use std.atomic
use sys
use asyncio.runtime as asyncrt
use asyncio.runtime.io as rtio

EMPTY<i32>           = 0
PARKED_CONDVAR<i32>  = 1
PARKED_DRIVER<i32>   = 2
NOTIFIED<i32>        = 3

PARK_DRIVER_SLICE_MS<u64> = 50

GATE_FREE<i32> = 0
GATE_HELD<i32> = 1

mem ParkDriverHub {
    asyncrt.Driver*       drv
    asyncrt.DriverHandle* handle
    rtio.IoHandle*        ioh
    i32                   time_on   // 1 when time driver published a handle
    i32                   drv_gate
}

mem Parker {
    u32            state
    ParkDriverHub* hub
}

mem Unparker {
    Parker* owner
}

const ParkDriverHub::new(drv<asyncrt.Driver>, handle<asyncrt.DriverHandle>, ioh<rtio.IoHandle>, time_on<i32>) ParkDriverHub {
    h<ParkDriverHub> = new ParkDriverHub
    h.drv = drv
    h.handle = handle
    h.ioh = ioh
    h.time_on = time_on
    h.drv_gate = GATE_FREE
    return h
}

ParkDriverHub::try_lock() i32 {
    if atomic.cas(&this.drv_gate, GATE_FREE, GATE_HELD) == CAS_OK {
        return 1
    }
    return 0
}

ParkDriverHub::unlock() {
    atomic.xchg(&this.drv_gate, GATE_FREE)
}

fn hub_try_lock(hub<ParkDriverHub>) i32 {
    if hub == null {
        return 0
    }
    return hub.try_lock()
}

fn hub_unlock(hub<ParkDriverHub>) {
    if hub == null {
        return
    }
    hub.unlock()
}

const Parker::new(hub<ParkDriverHub>) Parker {
    p<Parker> = new Parker
    p.state = EMPTY
    p.hub = hub
    return p
}

const Unparker::new(p<Parker>) Unparker {
    u<Unparker> = new Unparker
    u.owner = p
    return u
}

// Park slice for workers that lose the driver gate. Infinite futex (ns<0)
// matches MutexInter; Unparker futexwakeup returns promptly. Timed slices
// were only needed when block_on shared this path and starved timers.
Parker::park_condvar() {
    addr<i32*> = &this.state
    if atomic.cas(addr, EMPTY, PARKED_CONDVAR) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
        return
    }
    faddr<u32*> = &this.state
    loop {
        if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
            return
        }
        cur<i32> = *addr
        if cur != PARKED_CONDVAR {
            atomic.cas(addr, PARKED_CONDVAR, EMPTY)
            atomic.cas(addr, NOTIFIED, EMPTY)
            return
        }
        entered<i32> = runtime.entersyscall_mutexblock()
        runtime.futexsleep(faddr, PARKED_CONDVAR.(u32), 0 - 1)
        if entered != 0 {
            runtime.exitsyscall()
        }
    }
}

Parker::park_driver(handle_ptr<u64>) {
    addr<i32*> = &this.state
    hub<ParkDriverHub> = this.hub
    if atomic.cas(addr, EMPTY, PARKED_DRIVER) != CAS_OK {
        atomic.xchg(addr, EMPTY)
        hub_unlock(hub)
        return
    }
    drv<asyncrt.Driver> = hub.drv
    h<asyncrt.DriverHandle> = null
    if handle_ptr != 0 {
        h = handle_ptr
    } else {
        h = hub.handle
    }
    if drv != null && h != null {
        d<sys.Duration> = sys.Duration::from_millis(PARK_DRIVER_SLICE_MS)
        drv.park_timeout(h, d)
    }
    if atomic.cas(addr, PARKED_DRIVER, EMPTY) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
    }
    hub_unlock(hub)
}

Parker::wait_until_wake(handle_ptr<u64>) i32 {
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
        return 0
    }

    hub<ParkDriverHub> = this.hub
    if hub != null && hub.drv != null && hub.ioh != null {
        if hub_try_lock(hub) == 1 {
            this.park_driver(handle_ptr)
            return 0
        }
    }
    this.park_condvar()
    return 0
}

Parker::park_timeout(handle_ptr<u64>, max<sys.Duration>) i32 {
    hub<ParkDriverHub> = this.hub
    if hub != null && hub.drv != null && hub_try_lock(hub) == 1 {
        h<asyncrt.DriverHandle> = null
        if handle_ptr != 0 {
            h = handle_ptr
        } else {
            h = hub.handle
        }
        if h != null {
            drv<asyncrt.Driver> = hub.drv
            drv.park_timeout(h, max)
        }
        hub_unlock(hub)
        return 0
    }
    return this.wait_until_wake(handle_ptr)
}

Unparker::unpark(){
    p<Parker> = this.owner
    if p == null {
        return
    }
    addr<i32*> = &p.state
    old<i32> = atomic.xchg(addr, NOTIFIED)
    if old == PARKED_DRIVER {
        hub<ParkDriverHub> = p.hub
        if hub != null && hub.ioh != null {
            hub.ioh.wake_by_ref()
        }
    }
    if old == PARKED_CONDVAR {
        faddr<u32*> = &p.state
        runtime.futexwakeup(faddr, 1.(u32))
    }
}

Parker::shutdown(handle_ptr<u64>){
    u<Unparker> = Unparker::new(this)
    u.unpark()
    this.hub = null
}

// block_on park: try driver first. If the gate is held, do a short timed
// futex wait WITHOUT entering PARKED_CONDVAR — that state + block_on under
// accept load still loses wakes (ab hang). Unpark still stores NOTIFIED;
// the next loop iteration observes it. Timed wait cuts idle CPU vs osyield.
BLOCK_ON_GATE_WAIT_NS<i64> = 1000000

fn mt_park_block_on(p<Parker>, shared<MtShared>) {
    if p == null {
        return
    }
    addr<i32*> = &p.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
        return
    }
    hub<ParkDriverHub> = null
    if shared != null {
        hub = shared.park_hub
    }
    if hub == null {
        hub = p.hub
    }
    if hub == null || hub.drv == null {
        p.park_condvar()
        return
    }
    p.hub = hub

    if hub.ioh == null && hub.time_on == 0 {
        p.park_condvar()
        return
    }

    faddr<u32*> = &p.state
    loop {
        if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
            return
        }
        if hub_try_lock(hub) == 1 {
            hb<u64> = 0
            if hub.handle != null {
                hb = hub.handle.(u64)
            }
            p.park_driver(hb)
            return
        }
        // Expect EMPTY (or stale); WAIT returns when state changes or timeout.
        cur<u32> = *faddr
        entered<i32> = runtime.entersyscall_mutexblock()
        runtime.futexsleep(faddr, cur, BLOCK_ON_GATE_WAIT_NS)
        if entered != 0 {
            runtime.exitsyscall()
        }
    }
}
