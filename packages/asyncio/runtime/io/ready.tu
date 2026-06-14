// Pure bitset over readable / writable / closed / error / priority signals.
// Mirrors the boolean accessors on netio.Event so callers can OR-merge state
// across multiple turn() rounds without re-querying epoll.

use netio

// Readiness bit constants. Stored together so consumers can compose freely.
READABLE<i32>      = 0x01
WRITABLE<i32>      = 0x02
READ_CLOSED<i32>   = 0x04
WRITE_CLOSED<i32>  = 0x08
ERROR<i32>         = 0x10
PRIORITY<i32>      = 0x20

// Packed readiness bits.
mem Ready {
    i32 bits
}

// Empty Ready (no bits set).
const Ready::empty() Ready {
    return new Ready { bits: 0 }
}

// Build a Ready from raw bits (caller is responsible for validity).
const Ready::from_bits(b<i32>) Ready {
    return new Ready { bits: b }
}

// Project a netio.Event into Ready by OR-ing every triggered bit.
fn ready_from_event(ev<netio.Event>) Ready {
    b<i32> = 0
    if ev.is_readable()     b = b | READABLE
    if ev.is_writable()     b = b | WRITABLE
    if ev.is_read_closed()  b = b | READ_CLOSED
    if ev.is_write_closed() b = b | WRITE_CLOSED
    if ev.is_error()        b = b | ERROR
    if ev.is_priority()     b = b | PRIORITY
    return new Ready { bits: b }
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

// Bitwise OR with another Ready; returns a fresh value.
Ready::merge(other<Ready>) Ready {
    return new Ready { bits: this.bits | other.bits }
}

// Mask out bits in `mask`; returns a fresh Ready.
Ready::without(mask<Ready>) Ready {
    return new Ready { bits: this.bits & (~mask.bits) }
}

// Snapshot pairing a tick with a Ready set; clear_readiness uses tick to
// avoid clearing bits set after the snapshot was taken.
mem ReadyEvent {
    i32 tick
    Ready ready
}

// Build a ReadyEvent from tick + ready.
const ReadyEvent::new(tick<i32>, ready<Ready>) ReadyEvent {
    return new ReadyEvent { tick: tick, ready: ready }
}

