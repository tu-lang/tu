// AsyncRead source that yields a single byte forever. Useful as a
// fixed-pattern fixture in tests and a placeholder source in adapters.

use runtime
use std
use io as iobuf
use asyncio.io as aio

// Single-byte repeater. Each poll_read fills the destination's
// remaining capacity with `byte`.
mem Repeat {
    u8 byte
}

// Build a Repeat that yields `byte` indefinitely.
const Repeat::new(byte<u8>) Repeat {
    r<Repeat> = new Repeat
    r.byte = byte
    return r
}

// Convenience top-level constructor.
const repeat(byte<u8>) Repeat {
    return Repeat::new(byte)
}

// Fill the entire unfilled tail with the configured byte.
impl aio.AsyncRead for Repeat {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        room<u64> = dst.remaining()
        if room == 0 return runtime.PollReady
        base<u8*> = dst.inner.buf.inner + dst.filled.(i32)
        std.memset(base, this.byte.(i8), room)
        dst.advance(room)
        return runtime.PollReady
    }
}
