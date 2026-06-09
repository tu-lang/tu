// Pack: bit-field packing helper
// Related: packages-asyncio-runtime task 2.13 / 2.14, R22.1, R17.1
// Design: design §25.6
//
// Use cases: ScheduledIo readiness packs [shutdown:1 | tick:15 | readiness:16]
// into a single u64; multi_thread Idle.state packs [num_unparked:16 |
// num_searching:16] into a u32.  These layouts are described as a chain of
// Pack values:
//     READINESS = Pack::least_significant(16)
//     TICK      = READINESS.then(15)
//     SHUTDOWN  = TICK.then(1)
// Then SHUTDOWN.unpack(state) extracts the shutdown bit, TICK.pack(15, state)
// writes the tick field.

// A Pack describes one contiguous bit field:
//   mask  = full 1s mask within the field width (before shifting)
//   shift = bit offset of the field relative to base
mem Pack {
    u64 mask
    i32 shift
}

// least_significant(n): build a field starting at bit 0 with width n
const Pack::least_significant(n<i32>) Pack {
    p<Pack> = new Pack
    if n <= 0 {
        p.mask  = 0
        p.shift = 0
        return p
    }
    if n >= 64 {
        p.mask  = 0xFFFFFFFFFFFFFFFF
        p.shift = 0
        return p
    }
    p.mask  = (1.(u64) << n.(u64)) - 1
    p.shift = 0
    return p
}

// then(n): append a field of width n right after `this`; return a new Pack.
//   The new shift = this.shift + popcount(this.mask) (i.e. width of `this`).
Pack::then(n<i32>) Pack {
    p<Pack> = new Pack
    width<i32> = popcount_u64(this.mask)
    new_shift<i32> = this.shift + width
    if n <= 0 {
        p.mask  = 0
        p.shift = new_shift
        return p
    }
    p.mask  = (1.(u64) << n.(u64)) - 1
    p.shift = new_shift
    return p
}

// pack(value, base): write value into the Pack's field of base; return the
// new base.  Bits of value above the mask are truncated; other fields are
// unaffected.
Pack::pack(value<u64>, base<u64>) u64 {
    masked<u64> = value & this.mask
    cleared<u64> = base & (~(this.mask << this.shift.(u64)))
    return cleared | (masked << this.shift.(u64))
}

// unpack(base): extract the value of this field from base, right-shifted to
// bit 0.
Pack::unpack(base<u64>) u64 {
    return (base >> this.shift.(u64)) & this.mask
}

// popcount_u64: count the number of 1 bits in v.
//   Internal helper for util.bit; only paired with Pack::then.
fn popcount_u64(v<u64>) i32 {
    n<i32> = 0
    x<u64> = v
    while x != 0 {
        x &= (x - 1)
        n += 1
    }
    return n
}
