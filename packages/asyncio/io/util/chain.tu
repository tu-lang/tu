// Chain two AsyncRead sources (minimal stub-safe impl).

use runtime
use asyncio.io as aio

mem Chain {
    u64 first
    u64 second
    i32 on_second
}

const Chain::new(first<u64>, second<u64>) Chain {
    c<Chain> = new Chain
    c.first = first
    c.second = second
    c.on_second = 0
    return c
}

impl aio.AsyncRead for Chain {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        if this.on_second == 0 {
            before<u64> = dst.filled_len()
            err<i32> = this.first.(aio.AsyncRead).poll_read(ctx, dst)
            if err == runtime.PollPending return runtime.PollPending
            if err == runtime.PollError return runtime.PollError
            if dst.filled_len() == before {
                this.on_second = 1
            } else {
                return runtime.PollReady
            }
        }
        return this.second.(aio.AsyncRead).poll_read(ctx, dst)
    }
}
