// User-facing Duration, re-exporting sys.Duration (tustd) so callers
// `use asyncio.time` without reaching into sys directly.

use sys

// Build a Duration from whole seconds.
const Duration::from_secs(secs<u64>) sys.Duration {
    return sys.Duration::from_secs(secs)
}

// Build a Duration from milliseconds.
const Duration::from_millis(millis<u64>) sys.Duration {
    return sys.Duration::from_millis(millis)
}

// Build a Duration from microseconds.
const Duration::from_micros(micros<u64>) sys.Duration {
    return sys.Duration::from_micros(micros)
}

// Build a Duration from nanoseconds.
const Duration::from_nanos(nanos<u64>) sys.Duration {
    return sys.Duration::from_nanos(nanos)
}
