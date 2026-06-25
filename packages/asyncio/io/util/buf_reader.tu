// Buffered AsyncRead adapter. Wraps any AsyncRead source and an
// io.buffer.Buffer; consumers see the buffered window via AsyncBufRead
// while still being able to fall back to AsyncRead semantics. AsyncSeek
// is forwarded to the underlying source after dropping the buffer.

use runtime
use std
use io as iobuf
use asyncio.io as aio

// Default buffer size when callers do not specify one.
DEFAULT_BUF_CAP<u64> = 8192

// Buffered reader. `inner` is the raw bits of an AsyncRead implementor.
// `buf` is the backing Buffer; `pos` and `cap` track the consumed and
// filled offsets inside `buf` so we can replay buffered bytes without
// hitting the source again.
mem BufReader {
    u64           inner    // raw bits of an AsyncRead implementor
    iobuf.Buffer* buf      // pointer to the backing io.buffer.Buffer
    u64           pos      // first unread byte inside buf
    u64           cap      // one past the last filled byte inside buf
}

// Build a BufReader with `cap` bytes of buffer space.
const BufReader::with_capacity(inner<u64>, cap<u64>) BufReader {
    raw<iobuf.Buf> = iobuf.NewBuf(cap.(i32))
    backing<iobuf.Buffer> = iobuf.Buffer::from_uinit(raw)
    br<BufReader> = new BufReader
    br.inner = inner
    br.buf   = backing
    br.pos   = 0
    br.cap   = 0
    return br
}

// Build a BufReader with the default capacity.
const BufReader::new(inner<u64>) BufReader {
    return BufReader::with_capacity(inner, DEFAULT_BUF_CAP)
}

// True when the buffered window has been fully consumed.
BufReader::buffered_empty() bool {
    return this.pos >= this.cap
}

// Slice [pos, cap) of the backing buffer, i.e. the still-unread tail.
BufReader::buffered() iobuf.Buf {
    return new iobuf.Buf {
        inner: this.buf.buf.inner + this.pos.(i32),
        len:   this.cap - this.pos
    }
}

// Replenish the buffered window by driving the source's poll_read into
// our internal Buffer. Returns runtime.PollPending / Ready / Error.
fn buf_reader_refill(br<BufReader>, ctx<u64>) i32 {
    // Reset window before refill so we always start at offset 0.
    br.pos       = 0
    br.cap       = 0
    br.buf.filled = 0
    rb<aio.ReadBuf> = aio.ReadBuf::new(br.buf)
    err<i32> = br.inner.(aio.AsyncRead).poll_read(ctx, rb)
    if err == runtime.PollPending return runtime.PollPending
    if err == runtime.PollError   return runtime.PollError
    br.cap = rb.filled_len()
    return runtime.PollReady
}

// AsyncRead: serve from the buffered window first, fall back to
// poll_read against the source when the window is empty.
impl aio.AsyncRead for BufReader {
    fn poll_read(ctx<u64>, dst<aio.ReadBuf>) i32 {
        if this.buffered_empty() {
            err<i32> = buf_reader_refill(this, ctx)
            if err != runtime.PollReady return err
        }
        avail<iobuf.Buf> = this.buffered()
        room<u64>  = dst.remaining()
        take<u64>  = avail.len()
        if take > room take = room
        if take > 0 {
            slice<iobuf.Buf> = new iobuf.Buf {
                inner: avail.inner,
                len:   take
            }
            dst.put_slice(slice)
            this.pos = this.pos + take
        }
        return runtime.PollReady
    }
}

// AsyncBufRead: hand back the current buffered slice; refill on demand.
// consume() merely advances `pos`; refill happens lazily on the next
// poll_fill_buf when the window is exhausted.
impl aio.AsyncBufRead for BufReader {
    fn poll_fill_buf(ctx<u64>) (i32, iobuf.Buf) {
        if this.buffered_empty() {
            err<i32> = buf_reader_refill(this, ctx)
            if err != runtime.PollReady {
                return err, new iobuf.Buf { inner: null, len: 0 }
            }
        }
        return runtime.PollReady, this.buffered()
    }
    fn consume(amt<u64>){
        this.pos = this.pos + amt
        if this.pos > this.cap this.pos = this.cap
    }
}

// AsyncSeek: drop the buffered window before forwarding so the
// underlying source's view of "current position" matches what the
// caller expects.
impl aio.AsyncSeek for BufReader {
    fn start_seek(pos<aio.SeekFrom>) i32 {
        this.pos = 0
        this.cap = 0
        return this.inner.(aio.AsyncSeek).start_seek(pos)
    }
    fn poll_complete(ctx<u64>) (i32, u64) {
        return this.inner.(aio.AsyncSeek).poll_complete(ctx)
    }
}
