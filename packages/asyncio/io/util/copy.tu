// Generic AsyncRead -> AsyncWrite pump (stub leaf; full loop deferred).
// int_tcp_echo does not use copy(); keep a compile-clean leaf.

use runtime

mem Copy: async {
    u64 r
    u64 w
}

const Copy::new(r<u64>, w<u64>) Copy {
    f<Copy> = new Copy
    f.r = r
    f.w = w
    return f
}

Copy::poll(ctx) {
    return runtime.PollReady, 0, 0.(u64)
}

fn copy(r<u64>, w<u64>) Copy {
    return Copy::new(r, w)
}
