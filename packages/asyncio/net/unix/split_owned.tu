// Owned split of a UnixStream into read / write halves movable across tasks.
// Both halves hold a pointer to the same heap UnixStream (kept alive by the
// GC); reunite() recombines them.

use io
use asyncio.io as aio

// Owned read half; movable across tasks.
mem UnixOwnedReadHalf {
    UnixStream* backing
}

// Owned write half paired with a UnixOwnedReadHalf over the same stream.
mem UnixOwnedWriteHalf {
    UnixStream* backing
}

const UnixOwnedReadHalf::new(s<UnixStream>) UnixOwnedReadHalf {
    h<UnixOwnedReadHalf> = new UnixOwnedReadHalf
    h.backing = s
    return h
}

const UnixOwnedWriteHalf::new(s<UnixStream>) UnixOwnedWriteHalf {
    h<UnixOwnedWriteHalf> = new UnixOwnedWriteHalf
    h.backing = s
    return h
}

// Forward via UnixStream static members (avoid broken api dyn-call lea).
impl aio.AsyncRead for UnixOwnedReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.backing.poll_read(ctx, buf)
    }
}

impl aio.AsyncWrite for UnixOwnedWriteHalf {
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

// Recombine this read half with its paired write half. Returns (io.Ok, stream)
// when both reference the same backing stream, or (io.OtherParse, null) when
// they come from different splits.
UnixOwnedReadHalf::reunite(w<UnixOwnedWriteHalf>) i32, UnixStream {
    if this.backing != w.backing return io.OtherParse, null
    return io.Ok, this.backing
}

// Split into owned (read, write) halves sharing this stream.
UnixStream::into_split() UnixOwnedReadHalf, UnixOwnedWriteHalf {
    return UnixOwnedReadHalf::new(this), UnixOwnedWriteHalf::new(this)
}
