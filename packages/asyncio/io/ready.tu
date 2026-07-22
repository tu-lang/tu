// User-facing readiness bitset. Mirrors runtime.io.Ready but lives in the io package.
// Decimal/hex only: Tu currently evaluates 0b… binary literals as 0.

READABLE<i32>     = 0x01
WRITABLE<i32>     = 0x02
READ_CLOSED<i32>  = 0x04
WRITE_CLOSED<i32> = 0x08
ERROR<i32>        = 0x10
PRIORITY<i32>     = 0x20

mem Ready {
    i32 bits
}

const Ready::empty() Ready {
    r<Ready> = new Ready
    r.bits = 0
    return r
}

const Ready::from_bits(b<i32>) Ready {
    r<Ready> = new Ready
    r.bits = b
    return r
}

Ready::is_empty() i32 {
    if this.bits == 0 return 1
    return 0
}

Ready::is_readable() i32 {
    if (this.bits & READABLE) != 0 return 1
    return 0
}

Ready::is_writable() i32 {
    if (this.bits & WRITABLE) != 0 return 1
    return 0
}

Ready::is_read_closed() i32 {
    if (this.bits & READ_CLOSED) != 0 return 1
    return 0
}

Ready::is_write_closed() i32 {
    if (this.bits & WRITE_CLOSED) != 0 return 1
    return 0
}

Ready::is_error() i32 {
    if (this.bits & ERROR) != 0 return 1
    return 0
}

Ready::is_priority() i32 {
    if (this.bits & PRIORITY) != 0 return 1
    return 0
}
