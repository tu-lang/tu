// xorshift128+ PRNG; used for steal start randomisation and select fairness.
// Mirrors runtime.fastrand but as an owned struct so each worker holds its own.

// Two-state generator; algorithm only reads/writes the low 32 bits of each.
mem FastRand {
    u64 s0
    u64 s1
}

// Derive both cells from a single seed; guarantees neither cell is all-zero.
const FastRand::new(seed<u64>) FastRand {
    f<FastRand> = new FastRand
    f.s0 = seed * 1437154666 + 1
    f.s1 = seed * 65537 + 17
    return f
}

// Advance one step and return the low 32 bits.
FastRand::next_u32() u32 {
    s0<u32> = this.s0.(u32)
    s1<u32> = this.s1.(u32)
    s1 ^= s1 << 17
    s1  = s1 ^ s0 ^ (s1 >> 7) ^ (s0 >> 16)
    this.s0 = s0.(u64)
    this.s1 = s1.(u64)
    return (s0 + s1).(u32)
}

// Lemire fastrange in [0, n); n==0 returns 0.
FastRand::fastrand_n(n<u32>) u32 {
    if n == 0 return 0
    r<u32> = this.next_u32()
    prod<u64> = r.(u64) * n.(u64)
    return (prod >> 32).(u32)
}
