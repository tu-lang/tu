// Owned split of a TcpStream into read / write halves that can be moved into
// separate tasks independently. Both halves hold a pointer to the same
// heap-allocated TcpStream (kept alive by the GC), so neither borrows the
// other; reunite() recombines them back into the stream.

use net
use io
use asyncio.io as aio

// Owned read half; movable across tasks.
mem OwnedReadHalf {
    TcpStream* stream
}

// Owned write half paired with an OwnedReadHalf over the same stream.
mem OwnedWriteHalf {
    TcpStream* stream
}

// Wrap a TcpStream in an owned read half.
const OwnedReadHalf::new(s<TcpStream>) OwnedReadHalf {
    h<OwnedReadHalf> = new OwnedReadHalf
    h.stream = s
    return h
}

// Wrap a TcpStream in an owned write half.
const OwnedWriteHalf::new(s<TcpStream>) OwnedWriteHalf {
    h<OwnedWriteHalf> = new OwnedWriteHalf
    h.stream = s
    return h
}

// Cached remote address of the backing stream.
OwnedReadHalf::peer_addr() i32, net.SocketAddr {
    return this.stream.peer_addr()
}

OwnedWriteHalf::peer_addr() i32, net.SocketAddr {
    return this.stream.peer_addr()
}

// Forward the read side to the backing TcpStream's AsyncRead impl.
impl aio.AsyncRead for OwnedReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.stream.(aio.AsyncRead).poll_read(ctx, buf)
    }
}

// Forward all write-side ops to the backing TcpStream's AsyncWrite impl.
impl aio.AsyncWrite for OwnedWriteHalf {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        return this.stream.(aio.AsyncWrite).poll_write(ctx, buf)
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.stream.(aio.AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.stream.(aio.AsyncWrite).poll_shutdown(ctx)
    }
}

// Recombine this read half with its paired write half. Returns (io.Ok, stream)
// when both halves reference the same backing stream, or (io.OtherParse, null)
// when they come from different splits.
OwnedReadHalf::reunite(w<OwnedWriteHalf>) i32, TcpStream {
    if this.stream != w.stream return io.OtherParse, null
    return io.Ok, this.stream
}

// Split into owned (read, write) halves sharing this stream.
TcpStream::into_split() OwnedReadHalf, OwnedWriteHalf {
    return OwnedReadHalf::new(this), OwnedWriteHalf::new(this)
}
