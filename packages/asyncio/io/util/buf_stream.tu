// BufStream stub — empty adapter so asyncio.io.util compiles.

use runtime
use io as iobuf
use asyncio.io as aio

mem BufStream {
    i32 _pad
}

const BufStream::new(inner<u64>) BufStream {
    bs<BufStream> = new BufStream
    bs._pad = 0
    return bs
}

impl aio.AsyncRead for BufStream {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        return runtime.PollReady
    }
}

impl aio.AsyncBufRead for BufStream {
    fn poll_fill_buf(ctx<u64>) (i32, u64, u64) {
        return runtime.PollReady, 0.(u64), 0.(u64)
    }
    fn consume(amt<u64>){
    }
}

impl AsyncWrite for BufStream {
    fn poll_write(ctx<u64>, buf<iobuf.Buf>) i32, u64 {
        return runtime.PollReady, 0.(u64)
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return runtime.PollReady
    }
}
