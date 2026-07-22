// Bidirectional copy (stub leaf; full loop deferred).

use runtime

mem CopyBidirectional: async {
    u64 a
    u64 b
}

const CopyBidirectional::new(a<u64>, b<u64>) CopyBidirectional {
    f<CopyBidirectional> = new CopyBidirectional
    f.a = a
    f.b = b
    return f
}

CopyBidirectional::poll(ctx) {
    return runtime.PollReady, 0.(i64), 0.(u64), 0.(u64)
}

fn copy_bidirectional(a<u64>, b<u64>) CopyBidirectional {
    return CopyBidirectional::new(a, b)
}
