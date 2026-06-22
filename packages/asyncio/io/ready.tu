// User-facing readiness bitset. Mirrors runtime.io.Ready but lives in the
// io package so user code never has to use the runtime sub-tree.

use io as runtime_io

// Six readiness bits; mirror runtime.io.READABLE / WRITABLE / etc.
READABLE<i32>     = 0b00_0001
WRITABLE<i32>     = 0b00_0010
READ_CLOSED<i32>  = 0b00_0100
WRITE_CLOSED<i32> = 0b00_1000
ERROR<i32>        = 0b01_0000
PRIORITY<i32>     = 0b10_0000

// Snapshot of a single direction's readiness; bits is OR of the constants above.
mem Ready {
    i32 bits
}

// Build an empty Ready (no bits set).
const Ready::empty() Ready {
    r<Ready> = new Ready
    r.bits = 0
    return r
}

// Build a Ready from raw bits.
const Ready::from_bits(b<i32>) Ready {
    r<Ready> = new Ready
    r.bits = b
    return r
}

// True when no bits are set.
Ready::is_empty() bool {
    if this.bits == 0 return true
    return false
}

Ready::is_readable() bool {
    if (this.bits & READABLE) != 0 return true
    return false
}
Ready::is_writable() bool {
    if (this.bits & WRITABLE) != 0 return true
    return false
}
Ready::is_read_closed() bool {
    if (this.bits & READ_CLOSED) != 0 return true
    return false
}
Ready::is_write_closed() bool {
    if (this.bits & WRITE_CLOSED) != 0 return true
    return false
}
Ready::is_error() bool {
    if (this.bits & ERROR) != 0 return true
    return false
}
Ready::is_priority() bool {
    if (this.bits & PRIORITY) != 0 return true
    return false
}
