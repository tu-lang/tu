// Aggregate driver. Owns IoDriver / TimeDriver / SignalDriver; park
// routes through TimeDriver (for the next deadline) and IoDriver (for
// the actual epoll_wait). Each subsystem may be null when its feature
// flag is off.

use sys
use io as libio
use asyncio.util as util
use asyncio.runtime.io as rtio
use asyncio.runtime.time as rttime
use asyncio.runtime.signal as rtsig

// Strong-side aggregate held by Runtime.
// sdriver not sig_drv — `.sig_*` is a type-assert trap in this package.
// reactor not io_drv — `.io_*` is a type-assert trap (`use io as libio`).
mem Driver {
    rtio.IoDriver*       reactor
    rttime.TimeDriver*   time_drv
    rtsig.SignalDriver*  sigd       // not sdriver — member path edge cases
}

// Weak-side aggregate held by Handle / context. Cross-thread safe.
// Field names avoid `io_*` — outer/method `.io_handle` is a type-assert trap.
mem DriverHandle {
    rtio.IoHandle*           ihandle
    rttime.TimeHandle*         time_handle
    rtsig.SignalDriverHandle* signal_handle
}

// Pair returned by compose — avoids multi-ret dropping DriverHandle.
mem DriverPair {
    Driver*       drv
    DriverHandle* hdl
}

// Build a Driver pair. Caller passes already-created subsystems (or
// null) so feature flags compose cleanly.
const Driver::compose(io<rtio.IoDriver>, ioh<rtio.IoHandle>, time_drv<rttime.TimeDriver>, timeh<rttime.TimeHandle>, sdriver<rtsig.SignalDriver>, sigh<rtsig.SignalDriverHandle>) DriverPair {
    d<Driver> = new Driver
    d.reactor    = io
    d.time_drv   = time_drv
    d.sigd       = sdriver

    h<DriverHandle> = new DriverHandle
    h.ihandle       = ioh
    h.time_handle   = timeh
    h.signal_handle = sigh
    return new DriverPair { drv: d, hdl: h }
}

// Raw IoDriver* bits for scheduler park without `.reactor.(u64)` assert traps.
Driver::iod_bits() u64 {
    if this.reactor == null return 0
    bits<u64> = 0
    bits = this.reactor
    return bits
}

// Raw IoHandle* bits for scheduler park / registration.
DriverHandle::ioh_bits() u64 {
    if this.ihandle == null return 0
    bits<u64> = 0
    bits = this.ihandle
    return bits
}

// Raw TimeHandle* bits for asyncio.time Sleep (foreign pkgs must not
// read DriverHandle.time_handle — cross-pkg field type crashes).
DriverHandle::time_bits() u64 {
    if this.time_handle == null return 0
    bits<u64> = 0
    bits = this.time_handle
    return bits
}

// Raw SignalDriverHandle* bits for asyncio.signal (same cross-pkg rule).
DriverHandle::sigh_bits() u64 {
    if this.signal_handle == null return 0
    bits<u64> = 0
    bits = this.signal_handle
    return bits
}

// Package bridge for foreign packages.
fn driver_handle_time_bits(dh<DriverHandle>) u64 {
    if dh == null return 0
    return dh.time_bits()
}

fn driver_handle_sigh_bits(dh<DriverHandle>) u64 {
    if dh == null return 0
    return dh.sigh_bits()
}

// Park indefinitely. Time-aware: if the wheel has a near deadline we
// park up to that; otherwise we park "forever" (as far as the IO
// driver is concerned, that's poll(events, -1)).
Driver::park(handle<DriverHandle>) i32 {
    return this.park_timeout(handle, sys.MAX)
}

// Cross-pkg park via u64 slots (scheduler cannot annotate Driver*).
fn driver_park_bits(drv_bits<u64>, handle_bits<u64>) i32 {
    if drv_bits == 0 || handle_bits == 0 return -1
    drv<Driver> = drv_bits
    h<DriverHandle> = handle_bits
    return drv.park(h)
}

// Cross-pkg bounded park; millis avoids cross-pkg Duration arg traps.
fn driver_park_timeout_ms_bits(drv_bits<u64>, handle_bits<u64>, ms<u64>) i32 {
    if drv_bits == 0 || handle_bits == 0 return -1
    drv<Driver> = drv_bits
    h<DriverHandle> = handle_bits
    d<sys.Duration> = sys.Duration::from_millis(ms)
    return drv.park_timeout(h, d)
}

// Park for at most d. Time wheel narrows the wait if its next deadline
// is closer; IoDriver::turn handles signal events via TOKEN_SIGNAL.
//
// signalfd is registered EPOLLET. If a signal arrives while the reactor is
// not in epoll_wait, the edge is lost and a subsequent park would block
// forever. Pre-drain before turn; if any siginfo was applied, skip the
// blocking wait (RecvFut watches fired_count and will Ready on re-poll).
Driver::park_timeout(handle<DriverHandle>, d<sys.Duration>) i32 {
    sd<rtsig.SignalDriver> = this.sigd
    if sd != null {
        sd.process()
        if sd.park_skip != 0 {
            sd.park_skip = 0
            return 0
        }
    }
    err<i32> = 0
    if this.time_drv != null && handle.time_handle != null {
        ms<u64> = d.as_millis()
        err = this.time_drv.park_internal(handle.time_handle, ms, handle.ihandle)
    } else if this.reactor != null && handle.ihandle != null {
        err = this.reactor.turn(handle.ihandle, d)
    } else {
    }
    if sd != null {
        sd.process()
        if sd.park_skip != 0 {
            sd.park_skip = 0
            return 0
        }
    }
    return err
}

// Tear-down sequence: signal first (so signalfd is unregistered before
// the IO driver closes its registry), then IO. Time driver has no fd to close.
Driver::shutdown(handle<DriverHandle>){
    sd<rtsig.SignalDriver> = this.sigd
    if sd != null {
        sd.shutdown()
    }
    if handle.ihandle != null {
        handle.ihandle.shutdown()
    }
}

// Time-aware deadline hint. Returns -1 when there's nothing scheduled.
// EXPIR_FOUND=1 matches asyncio.runtime.time.wheel (asmgen cannot load pkg const).
DriverHandle::next_wake_ms() i32 {
    if this.time_handle == null return -1
    found<i32>, deadline<u64> = this.time_handle.wheel.poll_at()
    expir_found<i32> = 1
    if found != expir_found return -1
    return 0   // For now we just signal "something pending"; the actual
               // ms math lives in TimeDriver::park_internal.
}

