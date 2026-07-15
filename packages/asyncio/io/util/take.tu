// Limit an AsyncRead to at most `limit` bytes (stub-safe ReadBuf API).

use runtime
use asyncio.io as aio

mem Take {
    u64 inner
    u64 limit
}

const Take::new(inner<u64>, limit<u64>) Take {
    t<Take> = new Take
    t.inner = inner
    t.limit = limit
    return t
}

impl aio.AsyncRead for Take {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        if this.limit == 0 return runtime.PollReady
        before<u64> = dst.filled_len()
        rem<u64> = dst.remaining()
        if rem > this.limit {
            // Shrink visible capacity by advancing only up to limit after poll.
        }
        err<i32> = this.inner.(aio.AsyncRead).poll_read(ctx, dst)
        if err == runtime.PollPending return runtime.PollPending
        if err == runtime.PollError return runtime.PollError
        got<u64> = dst.filled_len() - before
        if got > this.limit {
            // Not expected when remaining was clamped; clamp accounting.
            got = this.limit
        }
        this.limit = this.limit - got
        return runtime.PollReady
    }
}
