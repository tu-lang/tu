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
TcpReadHalf::peer_addr() i32, net.SocketAddr {
    return this.stream.peer_addr()
}

TcpWriteHalf::peer_addr() i32, net.SocketAddr {
    return this.stream.peer_addr()
}

// Forward the read side to the backing TcpStream's AsyncRead impl.
impl aio.AsyncRead for TcpReadHalf {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.stream.(aio.AsyncRead).poll_read(ctx, buf)
    }
}

// Forward all write-side ops to the backing TcpStream's AsyncWrite impl.
impl aio.AsyncWrite for TcpWriteHalf {
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

// Split into borrowed (read, write) halves sharing this stream.
TcpStream::split() TcpReadHalf, TcpWriteHalf {
    return TcpReadHalf::new(this), TcpWriteHalf::new(this)
}
