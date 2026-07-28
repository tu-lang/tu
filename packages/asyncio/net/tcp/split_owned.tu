// Owned split of a TcpStream into read / write halves that can be moved into
// separate tasks independently. Both halves hold a pointer to the same
// heap-allocated TcpStream (kept alive by the GC), so neither borrows the
// other; reunite() recombines them back into the stream.

use net
use io
use asyncio.io as aio
use asyncio.io.util as ioutil

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
OwnedReadHalf::peer_addr() {
    return this.stream.peer_addr()
}

OwnedWriteHalf::peer_addr() {
    return this.stream.peer_addr()
}

// Forward via TcpStream static members (same rationale as split.tu: avoid
// broken api dyn-call lea of asyncio_io_Async*_poll_*).
impl aio.AsyncRead for OwnedReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.stream.poll_read(ctx, buf)
    }
}

impl ioutil.AsyncWrite for OwnedWriteHalf {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        err<i32>, n<u64> = this.stream.poll_write(ctx, buf)
        return err, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.stream.poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.stream.poll_shutdown(ctx)
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
