// Borrowed split of a UnixStream into independent read / write halves. Both
// halves share the backing UnixStream by pointer; the caller must keep the
// stream alive for their lifetime.

use io
use asyncio.io as aio

// Read-side borrowed view over a shared UnixStream.
mem UnixReadHalf {
    UnixStream* stream
}

// Write-side borrowed view over the same UnixStream.
mem UnixWriteHalf {
    UnixStream* stream
}

const UnixReadHalf::new(s<UnixStream>) UnixReadHalf {
    h<UnixReadHalf> = new UnixReadHalf
    h.stream = s
    return h
}

const UnixWriteHalf::new(s<UnixStream>) UnixWriteHalf {
    h<UnixWriteHalf> = new UnixWriteHalf
    h.stream = s
    return h
}

// Forward via UnixStream static members (avoid broken api dyn-call lea).
impl aio.AsyncRead for UnixReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.stream.poll_read(ctx, buf)
    }
}

impl aio.AsyncWrite for UnixWriteHalf {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        return this.stream.poll_write(ctx, buf_bits)
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.stream.poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.stream.poll_shutdown(ctx)
    }
}

// Split into borrowed (read, write) halves sharing this stream.
UnixStream::split() UnixReadHalf, UnixWriteHalf {
    return UnixReadHalf::new(this), UnixWriteHalf::new(this)
}
