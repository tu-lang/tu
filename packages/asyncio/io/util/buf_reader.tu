// BufReader stub — full buffer window deferred; compiles for package load.

use runtime
use io as iobuf
use asyncio.io as aio

mem BufReader {
    u64 inner
}

const BufReader::new(inner<u64>) BufReader {
    br<BufReader> = new BufReader
    br.inner = inner
    return br
}

const BufReader::with_capacity(inner<u64>, cap<u64>) BufReader {
    return BufReader::new(inner)
}

impl aio.AsyncRead for BufReader {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        return this.inner.(aio.AsyncRead).poll_read(ctx, dst)
    }
}

impl aio.AsyncBufRead for BufReader {
    fn poll_fill_buf(ctx<u64>) (i32, u64, u64) {
        return runtime.PollReady, 0.(u64), 0.(u64)
    }
    fn consume(amt<u64>){
    }
}
