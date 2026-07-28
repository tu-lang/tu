// AsyncWrite sink that swallows every byte and reports success.

use runtime
use io as iobuf

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

impl AsyncWrite for Sink {
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
