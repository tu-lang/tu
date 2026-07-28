// Split a single AsyncRead+AsyncWrite source into two independent halves
// that can be awaited in different tasks. The two halves share the same
// backing object (stored as raw bits); callers must ensure the backing
// outlives both halves.
//
// Buffer slots are u64 (io.Buf bits) — this package cannot `use io`.

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

impl AsyncWrite for WriteHalf {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        err<i32>, n<u64> = this.write_bits.(AsyncWrite).poll_write(ctx, buf_bits)
        return err, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.write_bits.(AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.write_bits.(AsyncWrite).poll_shutdown(ctx)
    }
}

fn split(rw<u64>) (ReadHalf, WriteHalf) {
    return ReadHalf::new(rw), WriteHalf::new(rw)
}
