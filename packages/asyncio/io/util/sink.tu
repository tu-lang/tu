// AsyncWrite sink that swallows every byte and reports success.

use runtime
use io as iobuf
use asyncio.io as aio

mem Sink {
    i32 _pad
}

const Sink::new() Sink {
    s<Sink> = new Sink
    s._pad = 0
    return s
}

fn sink() Sink {
    return Sink::new()
}

impl aio.AsyncWrite for Sink {
    fn poll_write(ctx<u64>, buf_bits<u64>) (i32, u64) {
        src<iobuf.Buf> = iobuf.buf_from_bits(buf_bits)
        return runtime.PollReady, src.len()
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return runtime.PollReady
    }
}
