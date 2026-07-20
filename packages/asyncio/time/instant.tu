// User-facing Instant bridges over asyncio.runtime.time's monotonic Instant.
// Mother: tokio::time::Instant::now().

use asyncio.runtime.time as rttime

// Sample the current monotonic instant.
fn now() rttime.Instant {
    return rttime.Instant::now()
}

// Nanoseconds elapsed from `earlier` to `later`; 0 when later <= earlier.
fn instant_sub_ns(later<rttime.Instant>, earlier<rttime.Instant>) u64 {
    return later.sub_ns(earlier)
}
