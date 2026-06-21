// Aggregate driver. Owns IoDriver / TimeDriver / SignalDriver; park
// routes through TimeDriver (for the next deadline) and IoDriver (for
// the actual epoll_wait). Each subsystem may be null when its feature
// flag is off.

use sys
use io

// Strong-side aggregate held by Runtime.
mem Driver {
    IoDriver*     io
    TimeDriver*   time
    SignalDriver* signal
}

// Weak-side aggregate held by Handle / context. Cross-thread safe.
mem DriverHandle {
    IoHandle*           io_handle
    TimeHandle*         time_handle
    SignalDriverHandle* signal_handle
}

// Build a Driver pair. Caller passes already-created subsystems (or
// null) so feature flags compose cleanly.
const Driver::compose(io<IoDriver>, ioh<IoHandle>, time<TimeDriver>, timeh<TimeHandle>, sig<SignalDriver>, sigh<SignalDriverHandle>) (Driver*, DriverHandle*) {
    d<Driver> = new Driver
    d.io     = io
    d.time   = time
    d.signal = sig

    h<DriverHandle> = new DriverHandle
    h.io_handle     = ioh
    h.time_handle   = timeh
    h.signal_handle = sigh
    return &d, &h
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
    if this.time != null && handle.time_handle != null {
        ms<u64> = d.secs * 1000 + d.nanos.inner.(u64) / 1000000
        return this.time.park_internal(handle.time_handle, ms)
    }
    if this.io != null && handle.io_handle != null {
        return this.io.turn(handle.io_handle, d)
    }
    return 0
}

// Tear-down sequence: signal first (so signalfd is unregistered before
// the IO driver closes its registry), then IO, then time.
Driver::shutdown(handle<DriverHandle>){
    if this.signal != null this.signal.shutdown()
    if this.io != null && handle.io_handle != null handle.io_handle.shutdown()
    // Time has no explicit shutdown — wheel just stops being polled.
}

// Time-aware deadline hint. Returns -1 when there's nothing scheduled.
DriverHandle::next_wake_ms() i32 {
    if this.time_handle == null return -1
    found<i32>, _<u64> = this.time_handle.wheel.poll_at()
    if found != EXPIR_FOUND return -1
    return 0   // For now we just signal "something pending"; the actual
               // ms math lives in TimeDriver::park_internal.
}

