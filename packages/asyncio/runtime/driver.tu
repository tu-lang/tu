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
mem Driver {
    rtio.IoDriver*       io_drv
    rttime.TimeDriver*   time_drv
    rtsig.SignalDriver*  sig_drv
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
const Driver::compose(io<rtio.IoDriver>, ioh<rtio.IoHandle>, time_drv<rttime.TimeDriver>, timeh<rttime.TimeHandle>, sig<rtsig.SignalDriver>, sigh<rtsig.SignalDriverHandle>) DriverPair {
    d<Driver> = new Driver
    d.io_drv     = io
    d.time_drv   = time_drv
    d.sig_drv    = sig

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

// Park indefinitely. Time-aware: if the wheel has a near deadline we
// park up to that; otherwise we park "forever" (as far as the IO
// driver is concerned, that's poll(events, -1)).
Driver::park(handle<DriverHandle>) i32 {
    return this.park_timeout(handle, sys.MAX)
}

// Park for at most d. Time wheel narrows the wait if its next deadline
// is closer; IoDriver::turn handles signal events via TOKEN_SIGNAL.
Driver::park_timeout(handle<DriverHandle>, d<sys.Duration>) i32 {
    if this.time_drv != null && handle.time_handle != null {
        ms<u64> = d.as_millis()
        return this.time_drv.park_internal(handle.time_handle, ms)
    }
    if this.io_drv != null && handle.ihandle != null {
        return this.io_drv.turn(handle.ihandle, d)
    }
    return 0
}

// Tear-down sequence: signal first (so signalfd is unregistered before
// the IO driver closes its registry), then IO, then time.
Driver::shutdown(handle<DriverHandle>){
    if this.sig_drv != null this.sig_drv.shutdown()
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

