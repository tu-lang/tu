// Monotonic millisecond clock anchored at runtime construction time.
// All wheel deadlines / interval ticks are expressed relative to `origin`
// so the u64 ms counter never overflows in practice.

// Monotonic ms source.
mem TimeSource {
    Instant origin
}

// Anchor TimeSource at the current monotonic instant.
const TimeSource::new() TimeSource* {
    s<TimeSource> = new TimeSource
    s.origin = Instant::now()
    return &s
}

// Milliseconds since origin.
TimeSource::now_ms() u64 {
    cur<Instant> = Instant::now()
    return cur.sub_ns(this.origin) / 1000000
}

// Convert a future deadline expressed in milliseconds since origin back to
// an absolute Instant; useful for IO Driver park_timeout calculations.
TimeSource::deadline_to_ns(deadline_ms<u64>) u64 {
    return this.origin.ns_since_epoch + deadline_ms * 1000000
}

