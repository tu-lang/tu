// User-facing Instant, re-exporting asyncio.runtime.time's monotonic
// Instant so callers `use asyncio.time` without reaching into runtime.time.

use asyncio.runtime.time as rttime

// Sample the current monotonic instant.
const Instant::now() rttime.Instant {
    return rttime.Instant::now()
}

// Nanoseconds elapsed from `earlier` to `later`; 0 when later <= earlier.
fn instant_sub_ns(later<rttime.Instant>, earlier<rttime.Instant>) u64 {
    return later.sub_ns(earlier)
}
