// FastRand: xorshift+ style fast pseudo-random generator
// Related: packages-asyncio-runtime task 2.11, R19.3, R45.1
// Design: design §25.5
//
// Uses the same algorithm as runtime.fastrand (see runtime/linux.tu) but
// packaged as a struct callers can own independently. Multi_thread workers
// each carry their own FastRand to randomise steal start indices, and
// select! relies on it for fairness.
// State: two u64 cells (only the low 32 bits matter to the algorithm).
//
// Algorithm (matches runtime.fastrand, an xorshift128+ variant):
//     s1 ^= s1 << 17
//     s1  = s1 ^ s0 ^ (s1 >> 7) ^ (s0 >> 16)
//     // implicit swap: store the new s1 back into c.fastrand[1], leave s0 as is
//     output = s0 + s1
//
// fastrand_n(n) uses the 64-bit multiplication trick (Lemire fastrange) to
// produce an unbiased value in [0, n).

mem FastRand {
    u64 s0
    u64 s1
}

// new(seed): initialise both cells from a single seed.
//   s0 = seed * 1437154666 + 1, s1 = seed * 65537 + 17 — guarantees neither
//   cell is all-zero.  Callers in multi-worker setups should derive distinct
//   seeds from worker_index/cputicks.
const FastRand::new(seed<u64>) FastRand {
    f<FastRand> = new FastRand
    f.s0 = seed * 1437154666 + 1
    f.s1 = seed * 65537 + 17
    return f
}

// next_u32(): advance one step and return the low 32 bits
FastRand::next_u32() u32 {
    s0<u32> = this.s0.(u32)
    s1<u32> = this.s1.(u32)
    s1 ^= s1 << 17
    s1  = s1 ^ s0 ^ (s1 >> 7) ^ (s0 >> 16)
    this.s0 = s0.(u64)
    this.s1 = s1.(u64)
    return (s0 + s1).(u32)
}

// fastrand_n(n): pseudo-random value in [0, n); returns 0 when n == 0.
//   Implementation: 64-bit multiply (u32 * u32) and take the high 32 bits;
//   equivalent to Lemire fastrange's low-bias variant.
FastRand::fastrand_n(n<u32>) u32 {
    if n == 0 return 0
    r<u32> = this.next_u32()
    prod<u64> = r.(u64) * n.(u64)
    return (prod >> 32).(u32)
}
