// Bit-field packing helper. Packs are chained via then(); pack/unpack are
// pure ops with no side effects.
//   READINESS = Pack::least_significant(16)
//   TICK      = READINESS.then(15)
//   SHUTDOWN  = TICK.then(1)

// Describes one contiguous bit field.
mem Pack {
    u64 mask     // 1s within field width, unshifted
    i32 bit_off  // bit offset relative to base
}

// Build a field starting at bit 0 with width n.
const Pack::least_significant(n<i32>) Pack {
    p<Pack> = new Pack
    if n <= 0 {
        p.mask  = 0
        p.bit_off = 0
        return p
    }
    if n >= 64 {
        p.mask  = 0xFFFFFFFFFFFFFFFF
        p.bit_off = 0
        return p
    }
    p.mask  = (1.(u64) << n.(u64)) - 1
    p.bit_off = 0
    return p
}

// Append a field of width n right after this Pack and return the new Pack.
Pack::then(n<i32>) Pack {
    p<Pack> = new Pack
    width<i32> = popcount_u64(this.mask)
    new_off<i32> = this.bit_off + width
    if n <= 0 {
        p.mask  = 0
        p.bit_off = new_off
        return p
    }
    p.mask  = (1.(u64) << n.(u64)) - 1
    p.bit_off = new_off
    return p
}

// Write value into this field of base. Truncates value to mask width;
// other fields of base are left untouched.
Pack::pack(value<u64>, base<u64>) u64 {
    masked<u64> = value & this.mask
    off<i32> = this.bit_off
    sh<u64> = off.(u64)
    allones<u64> = 0xFFFFFFFFFFFFFFFF
    inv_mask<u64> = allones ^ (this.mask << sh)
    out<u64> = base & inv_mask
    return out | (masked << sh)
}

// Extract this field's value from base, right-shifted to bit 0.
Pack::unpack(base<u64>) u64 {
    off<i32> = this.bit_off
    sh<u64> = off.(u64)
    return (base >> sh) & this.mask
}

// Package-level pack bridge (avoids p.pack parser trap).
fn pack_pack_field(p<Pack>, value<u64>, base<u64>) u64 {
    masked<u64> = value & p.mask
    off<i32> = p.bit_off
    sh<u64> = off.(u64)
    allones<u64> = 0xFFFFFFFFFFFFFFFF
    inv_mask<u64> = allones ^ (p.mask << sh)
    out<u64> = base & inv_mask
    return out | (masked << sh)
}

// Package-level then bridge (avoids p.then parser trap).
fn pack_then_next(p<Pack>, n<i32>) Pack {
    return p.then(n)
}

// Package-level unpack bridge (avoids ready_pack.unpack parser trap).
fn pack_unpack_field(p<Pack>, base<u64>) u64 {
    off<i32> = p.bit_off
    sh<u64> = off.(u64)
    return (base >> sh) & p.mask
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
