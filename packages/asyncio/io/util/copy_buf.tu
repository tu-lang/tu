// BufReader -> AsyncWrite pump (stub leaf; full loop deferred).

use runtime

mem CopyBuf: async {
    u64 br
    u64 w
}

const CopyBuf::new(br<u64>, w<u64>) CopyBuf {
    f<CopyBuf> = new CopyBuf
    f.br = br
    f.w = w
    return f
}

CopyBuf::poll(ctx) {
    return runtime.PollReady, 0.(i64), 0.(u64)
}

fn copy_buf(br<u64>, w<u64>) CopyBuf {
    return CopyBuf::new(br, w)
}
