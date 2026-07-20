// Aggregate driver. Owns IoDriver / TimeDriver / SignalDriver; park
// routes through TimeDriver (for the next deadline) and IoDriver (for
// the actual epoll_wait). Each subsystem may be null when its feature
// flag is off.

use sys
use io as libio
use asyncio.runtime.io as rtio
use asyncio.runtime.time as rttime
use asyncio.runtime.signal as rtsig

// Strong-side aggregate held by Runtime.
// sdriver not sig_drv — `.sig_*` is a type-assert trap in this package.
mem Driver {
    rtio.IoDriver*       io_drv
    rttime.TimeDriver*   time_drv
    rtsig.SignalDriver*  sdriver
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
    d.io_drv     = io
    d.time_drv   = time_drv
    d.sdriver    = sdriver

    h<DriverHandle> = new DriverHandle
    h.ihandle       = ioh
    h.time_handle   = timeh
    h.signal_handle = sigh
    return new DriverPair { drv: d, hdl: h }
}

// Raw IoDriver* bits for scheduler park without `.io_drv.(u64)` assert traps.
Driver::iod_bits() u64 {
    if this.io_drv == null return 0
    bits<u64> = 0
    bits = this.io_drv
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

// Park for at most d. Time wheel narrows the wait if its next deadline
// is closer; IoDriver::turn handles signal events via TOKEN_SIGNAL.
// Mother: signal::Driver::park — io.park then process().
Driver::park_timeout(handle<DriverHandle>, d<sys.Duration>) i32 {
    err<i32> = 0
    if this.time_drv != null && handle.time_handle != null {
        ms<u64> = d.as_millis()
        err = this.time_drv.park_internal(handle.time_handle, ms, handle.ihandle)
    } else if this.io_drv != null && handle.ihandle != null {
        err = this.io_drv.turn(handle.ihandle, d)
    }
    // Fan out queued signals after every reactor turn (mother process()).
    // Bridge via bits — avoid `.sdriver` member path edge cases.
    sb<u64> = 0
    sb = this.sdriver
    if sb != 0 {
        rtsig.signal_driver_process_bits(sb)
    }
    return err
}

// Tear-down sequence: signal first (so signalfd is unregistered before
// the IO driver closes its registry), then IO, then time.
Driver::shutdown(handle<DriverHandle>){
    sd<rtsig.SignalDriver> = this.sdriver
    if sd != null sd.shutdown()
    if this.io_drv != null && handle.ihandle != null handle.ihandle.shutdown()
    // Time has no explicit shutdown — wheel just stops being polled.
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

