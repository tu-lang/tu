// AsyncWrite sink that swallows every byte and reports success.

use runtime
use io as iobuf
use asyncio.io as aio

// Zero-state sink; payload sizes are reported back unchanged so callers
// see "every byte written" semantics.
mem Sink {
    i32 _pad
}

// Build a Sink.
const Sink::new() Sink {
    s<Sink> = new Sink
    s._pad = 0
    return s
}

// Convenience top-level constructor.
const sink() Sink {
    return Sink::new()
}

// All write-side ops succeed immediately. poll_write claims it accepted
// every byte so callers' write_all loops terminate on the first call.
impl aio.AsyncWrite for Sink {
    fn poll_write(ctx<u64>, src<iobuf.Buf>) (i32, u64) {
        return runtime.PollReady, src.len()
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return runtime.PollReady
    }
}
