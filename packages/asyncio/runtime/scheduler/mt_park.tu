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

// Workers that lose the driver gate. Mother uses Condvar::wait; we use a
// timed futex so the park loop can re-check try_lock (driver gate) and
// stranded inject. Idle sleepers membership remains the source of truth
// (transition_from_parked): timeout clears PARKED_CONDVAR → EMPTY so the
// next wait_until_wake may take the driver gate.
PARK_CONDVAR_SLICE_NS<i64> = 1000000

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
            atomic.cas(addr, NOTIFIED, EMPTY)
            return
        }
        entered<i32> = runtime.entersyscall_mutexblock()
        runtime.futexsleep(faddr, PARKED_CONDVAR.(u32), PARK_CONDVAR_SLICE_NS)
        if entered != 0 {
            runtime.exitsyscall()
        }
        // Timeout: drop PARKED so wait_until_wake can retry try_lock / inject.
        if atomic.cas(addr, PARKED_CONDVAR, EMPTY) == CAS_OK {
            return
        }
    }
}

Parker::park_driver(handle_ptr<u64>) {
    addr<i32*> = &this.state
    hub<ParkDriverHub> = this.hub
    // Mother: CAS EMPTY→PARKED_DRIVER; on NOTIFIED, swap EMPTY and return
    // (notification consumed). Do not xchg blindly — that could clear a
    // concurrent PARKED_* from a mismatched caller.
    if atomic.cas(addr, EMPTY, PARKED_DRIVER) != CAS_OK {
        cur<i32> = *addr
        if cur == NOTIFIED {
            atomic.xchg(addr, EMPTY)
        }
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
        // Bounded park (50ms). Driver::park(sys.MAX) → as_millis overflows and
        // Poll maps MAX to epoll -1; combined with timer-wheel path that is a
        // footgun. Unpark still wakes early via eventfd; entersyscall on epoll
        // keeps GC STW safe for the slice.
        asyncrt.driver_park_timeout_ms_bits(drv.(u64), h.(u64), PARK_DRIVER_SLICE_MS)
    }
    // Mother: swap EMPTY; NOTIFIED or PARKED_DRIVER both OK.
    old<i32> = atomic.xchg(addr, EMPTY)
    hub_unlock(hub)
}

Parker::wait_until_wake(handle_ptr<u64>) i32 {
    mt_hang_dump_maybe()
    addr<i32*> = &this.state
    if atomic.cas(addr, NOTIFIED, EMPTY) == CAS_OK {
        return 0
    }

    hub<ParkDriverHub> = this.hub
    if hub != null && hub.drv != null && hub.ioh != null {
        // Drain deferred close wakes before blocking — peers Pending on EOF
        // must run even if the last remove_source raced the previous turn.
        hub.ioh.flush_close_wakes()
        if hub_try_lock(hub) == 1 {
            this.park_driver(handle_ptr)
            return 0
        }
    }
    this.park_condvar()
    return 0
}

// Mother park_timeout: only Duration::ZERO is used (maintenance / defer).
// TryLock the driver and poll once; if the gate is held, return immediately
// — never fall through to wait_until_wake (that would block maintenance).
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
    }
    return 0
}

Unparker::unpark(){
    p<Parker> = this.owner
    if p == null {
        return
    }
    addr<i32*> = &p.state
    // Mother: swap NOTIFIED even when already NOTIFIED (release semantics).
    old<i32> = atomic.xchg(addr, NOTIFIED)
    if old == PARKED_DRIVER {
        hub<ParkDriverHub> = p.hub
        if hub != null && hub.ioh != null {
            hub.ioh.wake_by_ref()
        }
    }
    // PARKED_CONDVAR: worker park_condvar waiter.
    // EMPTY: mt_park_block_on may be in timed futexsleep(addr, EMPTY, …).
    // PARKED_DRIVER: also futexwake in case a waiter sits on the word.
    if old == PARKED_CONDVAR || old == EMPTY || old == PARKED_DRIVER {
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
    mt_hang_dump_maybe()
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
        if hub != null && hub.ioh != null {
            hub.ioh.flush_close_wakes()
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
