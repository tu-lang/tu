// Borrowed split of a TcpStream into independent read / write halves that can
// be awaited from different tasks. Both halves share the backing TcpStream
// (held by pointer); the caller must keep the stream alive for their lifetime.

use net
use io
use asyncio.io as aio

// Read-side borrowed view over a shared TcpStream.
mem TcpReadHalf {
    TcpStream* stream
}

// Write-side borrowed view over the same TcpStream as the paired read half.
mem TcpWriteHalf {
    TcpStream* stream
}

// Wrap a TcpStream in a borrowed read half.
const TcpReadHalf::new(s<TcpStream>) TcpReadHalf {
    h<TcpReadHalf> = new TcpReadHalf
    h.stream = s
    return h
}

// Wrap a TcpStream in a borrowed write half.
const TcpWriteHalf::new(s<TcpStream>) TcpWriteHalf {
    h<TcpWriteHalf> = new TcpWriteHalf
    h.stream = s
    return h
}

// Cached remote address of the backing stream.
TcpReadHalf::peer_addr() {
    return this.stream.peer_addr()
}

TcpWriteHalf::peer_addr() {
    return this.stream.peer_addr()
}

// Forward via TcpStream static members. Avoid `stream.(AsyncRead).poll_*`:
// current codegen emits lea of the api-method symbol (no body) instead of
// vtable dyn-dispatch, which leaves asyncio_io_Async*_poll_* undefined.
impl aio.AsyncRead for TcpReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.stream.poll_read(ctx, buf)
    }
}

impl aio.AsyncWrite for TcpWriteHalf {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        err<i32>, n<u64> = this.stream.poll_write(ctx, buf_bits)
        return err, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.stream.poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.stream.poll_shutdown(ctx)
    }
}

// Split into borrowed (read, write) halves sharing this stream.
TcpStream::split() TcpReadHalf, TcpWriteHalf {
    return TcpReadHalf::new(this), TcpWriteHalf::new(this)
}
