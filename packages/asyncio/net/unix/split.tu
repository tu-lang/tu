// Borrowed split of a UnixStream into independent read / write halves. Both
// halves share the backing UnixStream by pointer; the caller must keep the
// stream alive for their lifetime.

use io
use asyncio.io as aio

// Read-side borrowed view over a shared UnixStream.
mem UnixReadHalf {
    UnixStream* backing
}

// Write-side borrowed view over the same UnixStream.
mem UnixWriteHalf {
    UnixStream* backing
}

const UnixReadHalf::new(s<UnixStream>) UnixReadHalf {
    h<UnixReadHalf> = new UnixReadHalf
    h.backing = s
    return h
}

const UnixWriteHalf::new(s<UnixStream>) UnixWriteHalf {
    h<UnixWriteHalf> = new UnixWriteHalf
    h.backing = s
    return h
}

// Forward via UnixStream static members (avoid broken api dyn-call lea).
impl aio.AsyncRead for UnixReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.backing.poll_read(ctx, buf)
    }
}

impl aio.AsyncWrite for UnixWriteHalf {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        err<i32> = 0
        n<u64> = 0
        err, n = this.backing.poll_write(ctx, buf)
        return err, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.backing.poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.backing.poll_shutdown(ctx)
    }
}

// Split into borrowed (read, write) halves sharing this stream.
UnixStream::split() UnixReadHalf, UnixWriteHalf {
    return UnixReadHalf::new(this), UnixWriteHalf::new(this)
}
