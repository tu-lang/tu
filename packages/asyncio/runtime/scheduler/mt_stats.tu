// Multi-thread scheduler stats placeholder. First-pass exposes only the
// poll counter; adaptive EMA + per-worker breakdown lands later.

// Aggregate counters; all members are atomic-bump-only in this first pass.
mem Stats {
    u64 polls       // total task polls observed
    u64 total_ns    // total ns spent inside poll (reserved; 0 in v1)
}

// Build a fresh Stats with all counters zeroed.
const Stats::new() Stats {
    s<Stats> = new Stats
    s.polls    = 0
    s.total_ns = 0
    return s
}

// Bump the poll counter. Plain add — concurrent increments may collide;
// the EMA path that needs precision will move to atomic.xadd64 later.
Stats::incr_poll_count(){
    this.polls += 1
}

// EMA over per-poll wall time. First pass returns the cumulative poll
// counter so the runtime root has a value to feed into stats hooks.
Stats::task_poll_time_ns_ema() u64 {
    return this.polls
}
