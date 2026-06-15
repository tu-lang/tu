// Monotonic timestamp in nanoseconds since an unspecified epoch.
// Backed by std.clock_gettime(CLOCK_MONOTONIC).

use std

// Monotonic instant; only differences are meaningful.
mem Instant {
    u64 ns_since_epoch
}

// Sample CLOCK_MONOTONIC. ts.sec/nsec failure mode is "all zeros", which
// matches what std.ntime() does — callers can treat ns_since_epoch == 0
// as a transient failure if they need to.
const Instant::now() Instant {
    ts<std.TimeSpec:> = null
    std.clock_gettime(std.CLOCK_MONOTONIC, ts)
    n<u64> = (ts.sec.(u64)) * 1000000000 + ts.nsec.(u64)
    return new Instant { ns_since_epoch: n }
}

// Nanoseconds elapsed since `earlier`. Returns 0 when later <= earlier.
Instant::sub_ns(earlier<Instant>) u64 {
    if this.ns_since_epoch <= earlier.ns_since_epoch return 0
    return this.ns_since_epoch - earlier.ns_since_epoch
}

