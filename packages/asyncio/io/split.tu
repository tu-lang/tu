// Split a single AsyncRead+AsyncWrite source into two independent halves
// that can be awaited in different tasks. The two halves share the same
// backing object (stored as raw bits); callers must ensure the backing
// outlives both halves.
//
// AsyncWrite impl for WriteHalf is in asyncio.io.util (same package as the
// AsyncWrite api) so library Buf can be named without poisoning this package.

use runtime

mem ReadHalf {
    u64 read_bits
}

mem WriteHalf {
    u64 write_bits
}

const ReadHalf::new(bits<u64>) ReadHalf {
    rh<ReadHalf> = new ReadHalf
    rh.read_bits = bits
    return rh
}

const WriteHalf::new(bits<u64>) WriteHalf {
    wh<WriteHalf> = new WriteHalf
    wh.write_bits = bits
    return wh
}

impl AsyncRead for ReadHalf {
    fn poll_read(ctx<u64>, buf<ReadBuf>) i32 {
        return this.read_bits.(AsyncRead).poll_read(ctx, buf)
    }
}

fn split(rw<u64>) (ReadHalf, WriteHalf) {
    return ReadHalf::new(rw), WriteHalf::new(rw)
}
