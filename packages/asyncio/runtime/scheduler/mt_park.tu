// Worker park / unpark. State machine matches mother park.rs
// (EMPTY / PARKED_CONDVAR / PARKED_DRIVER / NOTIFIED).
//
// Tu GC STW requires threads to call osyield/schedule. Infinite Note.Sleep
// or unbounded epoll_wait would deadlock stopSTW — so condvar falls back to
// osyield polling, and PARKED_DRIVER uses bounded driver parks with osyield
// between mother-style single park calls. Unpark of PARKED_DRIVER kicks eventfd.

use runtime
use std.atomic
use sys
use asyncio.runtime as asyncrt
use asyncio.runtime.io as rtio

EMPTY<i32>           = 0
PARKED_CONDVAR<i32>  = 1
PARKED_DRIVER<i32>   = 2
NOTIFIED<i32>        = 3

// Bounded driver wait so workers re-enter osyield and can join GC STW.
PARK_DRIVER_SLICE_MS<u64> = 50

// Try-lock word for shared Driver (typed sentinels — bare 0/1 break cas).
GATE_FREE<i32> = 0
GATE_HELD<i32> = 1

// Shared across all workers' Parkers (mother Arc<Shared> + TryLock<Driver>).
mem ParkDriverHub {
    u64 drv_bits
    u64 handle_bits
    u64 ioh_bits
    u64 time_bits              // TimeHandle bits; 0 = time driver off
    i32 drv_gate               // GATE_FREE / GATE_HELD
}

mem Parker {
    i32            state
    ParkDriverHub* hub
}

mem Unparker {
    Parker* owner
}

const ParkDriverHub::new(drv_bits<u64>, handle_bits<u64>, ioh_bits<u64>, time_bits<u64>) ParkDriverHub {
    h<ParkDriverHub> = new ParkDriverHub
    h.drv_bits = drv_bits
    h.handle_bits = handle_bits
    h.ioh_bits = ioh_bits
    h.time_bits = time_bits
    h.drv_gate = GATE_FREE
    return h
}

// CAS_OK is i32 in this package (mt_queue); do not use CAS64_OK here.
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

// Mother park_condvar stand-in: osyield poll (GC-safe). Note.Sleep would
// block stopSTW forever because it never observes gcwaiting.
Parker::park_condvar() {
    addr<i32*> = &this.state
    if atomic.cas(addr, EMPTY, PARKED_CONDVAR) != CAS_OK {
        atomic.cas(addr, NOTIFIED, EMPTY)
        return
    }
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
        runtime.osyield()
    }
}

// Mother park_driver: one driver.park then release the try-lock.
// Tu GC: unbounded epoll_wait deadlocks STW, so each call uses a bounded
// slice; the outer wait loop re-enters for the next slice.
// osyield only after unlock — holding drv_gate across schedule()/STW is unsafe
// and was observed to SEGV when yielding inside park_internal / mid-park.
Parker::park_driver(handle_ptr<u64>) {
    addr<i32*> = &this.state
    hub<ParkDriverHub> = this.hub
    if atomic.cas(addr, EMPTY, PARKED_DRIVER) != CAS_OK {
        atomic.xchg(addr, EMPTY)
        hub_unlock(hub)
        return
    }
    drv_bits<u64> = hub.drv_bits
    h_bits<u64> = handle_ptr
    if h_bits == 0 {
        h_bits = hub.handle_bits
    }
    asyncrt.driver_park_timeout_ms_bits(drv_bits, h_bits, PARK_DRIVER_SLICE_MS)
    atomic.xchg(addr, EMPTY)
    hub_unlock(hub)
    runtime.osyield()
}

// Park until unpark. Prefer shared driver when an IoHandle exists (mother).
// Time-only runtimes: workers must not steal the driver TryLock — only
// block_on advances the wheel; workers park_condvar and wait for unpark.
Parker::wait_until_wake(handle_ptr<u64>) i32 {
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
        return 0
    }

    hub<ParkDriverHub> = this.hub
    if hub != null && hub.drv_bits != 0 && hub.ioh_bits != 0 {
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
    if hub != null && hub.drv_bits != 0 && hub_try_lock(hub) == 1 {
        h_bits<u64> = handle_ptr
        if h_bits == 0 {
            h_bits = hub.handle_bits
        }
        ms<u64> = max.as_millis()
        asyncrt.driver_park_timeout_ms_bits(hub.drv_bits, h_bits, ms)
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
    // Interrupt epoll early when the driver holder is in PARKED_DRIVER.
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

// block_on wait: mother TryLock<Driver> then park. Spawn-only (no time, no
// IO): condvar — empty Driver has nothing to park. Time-only: workers never
// take the lock (wait_until_wake); block_on always TryLocks like IO path.
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
    if hub == null || hub.drv_bits == 0 {
        p.park_condvar()
        return
    }
    p.hub = hub

    // No drivers that need parking: spawn-only pool.
    if hub.ioh_bits == 0 && hub.time_bits == 0 {
        p.park_condvar()
        return
    }

    loop {
        if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
            return
        }
        if hub_try_lock(hub) == 1 {
            p.park_driver(hub.handle_bits)
            return
        }
        runtime.osyield()
    }
}
