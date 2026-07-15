// AsyncRead that repeats a single byte (stub poll for compile).

use runtime
use asyncio.io as aio

mem Repeat {
    u8 byte
}

const Repeat::new(byte<u8>) Repeat {
    r<Repeat> = new Repeat
    r.byte = byte
    return r
}

fn repeat(byte<u8>) Repeat {
    return Repeat::new(byte)
}

impl aio.AsyncRead for Repeat {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        rem<u64> = dst.remaining()
        if rem == 0 return runtime.PollReady
        p<u8*> = dst.unfilled_ptr()
        i<u64> = 0
        while i < rem {
            p[i] = this.byte
            i = i + 1
        }
        dst.advance(rem)
        return runtime.PollReady
    }
}
