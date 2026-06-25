// Buffered AsyncWrite adapter. Coalesces small writes into a larger
// internal buffer, then flushes the buffer with a single poll_write to
// the underlying sink. Flush is explicit; shutdown drains the buffer
// before delegating to the underlying poll_shutdown.

use runtime
use std
use io as iobuf
use asyncio.io as aio

// Default buffer size when callers do not specify one.
DEFAULT_WBUF_CAP<u64> = 8192

// `inner` is the raw bits of an AsyncWrite sink. `buf` accumulates
// pending bytes; `pos` tracks how much of `buf` has already been
// drained to the sink (so a partial poll_write can resume from the
// right offset on the next flush attempt).
mem BufWriter {
    u64           inner   // raw bits of an AsyncWrite implementor
    iobuf.Buffer* buf
    u64           pos     // first unsent byte inside buf
}

// Build a BufWriter with `cap` bytes of buffer space.
const BufWriter::with_capacity(inner<u64>, cap<u64>) BufWriter {
    raw<iobuf.Buf>        = iobuf.NewBuf(cap.(i32))
    backing<iobuf.Buffer> = iobuf.Buffer::from_uinit(raw)
    bw<BufWriter> = new BufWriter
    bw.inner = inner
    bw.buf   = backing
    bw.pos   = 0
    return bw
}

// Build a BufWriter with the default capacity.
const BufWriter::new(inner<u64>) BufWriter {
    return BufWriter::with_capacity(inner, DEFAULT_WBUF_CAP)
}

// Bytes still pending in the buffer.
BufWriter::pending() u64 {
    return this.buf.filled - this.pos
}

// Free space remaining in the buffer.
BufWriter::room() u64 {
    return this.buf.capacity() - this.buf.filled
}

// Drive a single poll_write to push `pending` bytes into the sink.
// Returns runtime.PollPending / Ready / Error; on Ready the buffer is
// reset when fully drained, otherwise `pos` advances and we stay in
// the partial-flush state.
fn buf_writer_push(bw<BufWriter>, ctx<u64>) i32 {
    if bw.pending() == 0 {
        return runtime.PollReady
    }
    base<u8*> = bw.buf.buf.inner + bw.pos.(i32)
    slice<iobuf.Buf> = new iobuf.Buf { inner: base, len: bw.pending() }
    err<i32>, n<u64> = bw.inner.(aio.AsyncWrite).poll_write(ctx, slice)
    if err == runtime.PollPending return runtime.PollPending
    if err == runtime.PollError   return runtime.PollError
    if n == 0 {
        // Stalled writer — surface as PollError so write_all-style
        // callers convert this into iobuf.WriteZero.
        return runtime.PollError
    }
    bw.pos = bw.pos + n
    if bw.pos >= bw.buf.filled {
        bw.pos = 0
        bw.buf.filled = 0
    }
    return runtime.PollReady
}

// AsyncWrite: small writes land in `buf`; oversize writes drain the
// buffer first, then delegate straight to the sink.
impl aio.AsyncWrite for BufWriter {
    fn poll_write(ctx<u64>, src<iobuf.Buf>) (i32, u64) {
        // If the caller's slice would not fit, flush the buffer first.
        if src.len() > this.room() {
            err<i32> = buf_writer_push(this, ctx)
            if err == runtime.PollPending return runtime.PollPending, 0.(u64)
            if err == runtime.PollError   return runtime.PollError, 0.(u64)
            // After a successful flush, large writes bypass the buffer.
            if src.len() >= this.buf.capacity() {
                return this.inner.(aio.AsyncWrite).poll_write(ctx, src)
            }
        }
        // Append into our buffer.
        dst<u8*> = this.buf.buf.inner + this.buf.filled.(i32)
        std.memcpy(dst, src.inner, src.len())
        this.buf.filled = this.buf.filled + src.len()
        return runtime.PollReady, src.len()
    }
    fn poll_flush(ctx<u64>) i32 {
        // Drain the internal buffer first, then flush the sink.
        loop {
            if this.pending() == 0 break
            err<i32> = buf_writer_push(this, ctx)
            if err != runtime.PollReady return err
        }
        return this.inner.(aio.AsyncWrite).poll_flush(ctx)
    }
    fn poll_shutdown(ctx<u64>) i32 {
        loop {
            if this.pending() == 0 break
            err<i32> = buf_writer_push(this, ctx)
            if err != runtime.PollReady return err
        }
        return this.inner.(aio.AsyncWrite).poll_shutdown(ctx)
    }
}
