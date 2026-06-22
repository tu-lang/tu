// User-facing Interest re-exporting netio.Interest. Users `use asyncio.io`
// and never need to touch netio directly.

use netio

// Re-export bit constants so callers can write `io.READABLE`.
READABLE<u8> = netio.READABLE_BIT
WRITABLE<u8> = netio.WRITABLE_BIT

// Build an Interest that fires on read readiness.
const Interest::readable() netio.Interest {
    return netio.Interest_readable()
}

// Build an Interest that fires on write readiness.
const Interest::writable() netio.Interest {
    return netio.Interest_writable()
}

// Combine two Interests.
fn interest_add(a<netio.Interest>, b<netio.Interest>) netio.Interest {
    return a.add(b)
}
