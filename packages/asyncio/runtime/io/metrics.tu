// IO driver metrics stub. First-pass keeps the counters a no-op so the
// hot path stays branchless; the surface mirrors what the tracing/metrics
// build will fill in.

// Counters consumed by the runtime metrics handle.
mem Metrics {
    u64 ready_count
}

// Build a zeroed Metrics.
const Metrics::new() Metrics {
    return new Metrics { ready_count: 0 }
}

// Bump ready_count by n. First-pass impl is a plain add; will move to
// atomic add when multi_thread runtime metrics land.
Metrics::incr_ready_count_by(n<u64>){
    this.ready_count += n
}

// Snapshot accessor; reads without atomics in the first-pass impl.
Metrics::ready_count_snapshot() u64 {
    return this.ready_count
}

