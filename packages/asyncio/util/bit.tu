// Bit-field packing helper. Packs are chained via then(); pack/unpack are
// pure ops with no side effects.
//   READINESS = Pack::least_significant(16)
//   TICK      = READINESS.then(15)
//   SHUTDOWN  = TICK.then(1)

// Describes one contiguous bit field.
mem Pack {
    u64 mask     // 1s within field width, unshifted
    i32 shift    // bit offset relative to base
}

// Build a field starting at bit 0 with width n.
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

// Append a field of width n right after this Pack and return the new Pack.
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

// Write value into this field of base. Truncates value to mask width;
// other fields of base are left untouched.
Pack::pack(value<u64>, base<u64>) u64 {
    masked<u64> = value & this.mask
    cleared<u64> = base & (~(this.mask << this.shift.(u64)))
    return cleared | (masked << this.shift.(u64))
}

// Extract this field's value from base, right-shifted to bit 0.
Pack::unpack(base<u64>) u64 {
    return (base >> this.shift.(u64)) & this.mask
}

// Count the number of 1 bits in v.
fn popcount_u64(v<u64>) i32 {
    n<i32> = 0
    x<u64> = v
    while x != 0 {
        x &= (x - 1)
        n += 1
    }
    return n
}
