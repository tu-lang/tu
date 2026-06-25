// Combined buffered stream wrapping the same AsyncRead+AsyncWrite source
// behind a BufReader and BufWriter. Convenient when the user wants
// buffering on both directions of one full-duplex object (e.g. TcpStream).

use runtime
use io as iobuf
use asyncio.io as aio

// `br` buffers the read direction, `bw` buffers the write direction.
// Both halves point at the same underlying source (caller passes its
// raw bits twice on construction).
mem BufStream {
    aio.BufReader* br
    aio.BufWriter* bw
}

// Build a BufStream with default capacities for both halves.
const BufStream::new(rw<u64>) BufStream {
    bs<BufStream> = new BufStream
    bs.br = aio.BufReader::new(rw)
    bs.bw = aio.BufWriter::new(rw)
    return bs
}

// Build a BufStream with explicit read / write capacities.
const BufStream::with_capacities(rw<u64>, rcap<u64>, wcap<u64>) BufStream {
    bs<BufStream> = new BufStream
    bs.br = aio.BufReader::with_capacity(rw, rcap)
    bs.bw = aio.BufWriter::with_capacity(rw, wcap)
    return bs
}

// AsyncRead: forward to the read-side BufReader.
impl aio.AsyncRead for BufStream {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        return this.br.(aio.AsyncRead).poll_read(ctx, dst)
    }
}

// AsyncBufRead: forward both poll_fill_buf and consume to BufReader.
impl aio.AsyncBufRead for BufStream {
    fn poll_fill_buf(ctx<u64>) (i32, iobuf.Buf) {
        return this.br.(aio.AsyncBufRead).poll_fill_buf(ctx)
    }
    fn consume(amt<u64>){
        this.br.(aio.AsyncBufRead).consume(amt)
    }
}

// AsyncWrite: forward to the write-side BufWriter.
impl aio.AsyncWrite for BufStream {
    fn poll_write(ctx<u64>, src<iobuf.Buf>) (i32, u64) {
        return this.bw.(aio.AsyncWrite).poll_write(ctx, src)
    }
    fn poll_flush(ctx<u64>) i32 {
        return this.bw.(aio.AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        return this.bw.(aio.AsyncWrite).poll_shutdown(ctx)
    }
}
