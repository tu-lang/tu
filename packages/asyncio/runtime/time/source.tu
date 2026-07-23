// Monotonic millisecond clock anchored at runtime construction time.
// All wheel deadlines / interval ticks are expressed relative to `origin`
// so the u64 ms counter never overflows in practice.

use std

// Monotonic ms source. Stores origin as raw ns — embedding Instant by value
// left origin at 0 (Instant::now() heap assign did not copy ns_since_epoch),
// so now_ms() looked like absolute CLOCK_MONOTONIC and desynced the wheel.
mem TimeSource {
    u64 origin_ns
}

// Read CLOCK_MONOTONIC as nanoseconds.
fn mono_ns_now() u64 {
    ts<std.TimeSpec:> = null
    std.clock_gettime(std.CLOCK_MONOTONIC, ts)
    sec_v<i64> = ts.sec
    nsec_v<i64> = ts.nsec
    return (sec_v.(u64)) * 1000000000 + nsec_v.(u64)
}

// Anchor TimeSource at the current monotonic instant.
const TimeSource::new() TimeSource {
    s<TimeSource> = new TimeSource
    s.origin_ns = mono_ns_now()
    return s
}

// Milliseconds since origin.
TimeSource::now_ms() u64 {
    cur_ns<u64> = mono_ns_now()
    if cur_ns <= this.origin_ns return 0
    return (cur_ns - this.origin_ns) / 1000000
}

// Convert a future deadline expressed in milliseconds since origin back to
// absolute monotonic ns; useful for IO Driver park_timeout calculations.
TimeSource::deadline_to_ns(deadline_ms<u64>) u64 {
    return this.origin_ns + deadline_ms * 1000000
}
