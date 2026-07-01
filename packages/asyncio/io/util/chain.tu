// AsyncRead adapter that exhausts a primary source first, then falls
// through to a secondary source. Mirrors std::io::Chain.

use runtime
use io as iobuf
use asyncio.io as aio

// `first` and `second` are raw bits of AsyncRead implementors; once
// `first` reports EOF we latch `done_first = 1` and forward all reads
// to `second` from then on.
mem Chain {
    u64 first       // raw bits of an AsyncRead implementor
    u64 second      // raw bits of an AsyncRead implementor
    i32 done_first  // 1 once first has signalled EOF
}

// Build a Chain that reads `first` then `second`.
const Chain::new(first<u64>, second<u64>) Chain {
    c<Chain> = new Chain
    c.first      = first
    c.second     = second
    c.done_first = 0
    return c
}

// Convenience top-level constructor.
const chain(first<u64>, second<u64>) Chain {
    return Chain::new(first, second)
}

// AsyncRead: poll `first` until EOF; on EOF without bytes flip the
// done flag and forward to `second`. EOF detection mirrors the
// `read` helper: an inner Ready that did not advance dst.filled.
impl aio.AsyncRead for Chain {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        if this.done_first {
            return this.second.(aio.AsyncRead).poll_read(ctx, dst)
        }
        before<u64> = dst.filled_len()
        err<i32>    = this.first.(aio.AsyncRead).poll_read(ctx, dst)
        if err == runtime.PollPending return runtime.PollPending
        if err == runtime.PollError   return runtime.PollError
        if dst.filled_len() == before {
            // First source signalled EOF; switch and try second on
            // this same call so callers do not see a phantom 0-byte
            // Ready.
            this.done_first = 1
            return this.second.(aio.AsyncRead).poll_read(ctx, dst)
        }
        return runtime.PollReady
    }
}
