// User-facing Duration, re-exporting sys.Duration (tustd) so callers
// `use asyncio.time` without reaching into sys directly.

use sys

// Package bridges — callers cannot write `time.Duration::from_*` (static call
// path), so package-level from_* functions are provided instead.

fn from_secs(secs<u64>) sys.Duration {
    return sys.Duration::from_secs(secs)
}

fn from_millis(millis<u64>) sys.Duration {
    return sys.Duration::from_millis(millis)
}

fn from_micros(micros<u64>) sys.Duration {
    return sys.Duration::from_micros(micros)
}

fn from_nanos(nanos<u64>) sys.Duration {
    return sys.Duration::from_nanos(nanos)
}
