// AsyncBufRead extension helpers. fill_buf is a one-shot leaf future
// over poll_fill_buf; Lines / Split provide pull-style iterators that
// emit one record per await. Records are delivered via destination
// io.buffer.Buffer slots so we never return dynamic strings.

use runtime
use std
use io as iobuf
use asyncio.io as aio

// LF separator used by Lines.
LF<u8> = 10

// Leaf future for a single AsyncBufRead::poll_fill_buf call. `r` is
// the raw bits of an AsyncBufRead implementor; the PollReady payload
// is the slice the implementor handed back (may be empty on EOF).
mem FillBuf: async {
    u64       r
    iobuf.Buf out_buf       // last slice received from poll_fill_buf
    i32       out_err       // PollPending / PollReady / PollError
}

// Build a FillBuf leaf targeting buffered reader `r`.
const FillBuf::new(r<u64>) FillBuf {
    f<FillBuf> = new FillBuf
    f.r       = r
    f.out_buf = new iobuf.Buf { inner: null, len: 0 }
    f.out_err = runtime.PollPending
    return f
}

// Drive one poll_fill_buf. Stores the resulting slice on `this` so the
// async wrapper can inspect it after the await.
FillBuf::poll(ctx) {
    err<i32>, buf<iobuf.Buf> = this.r.(aio.AsyncBufRead).poll_fill_buf(ctx)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    this.out_err = err
    this.out_buf = buf
    return runtime.PollReady, 0.(u64)
}

// Wait until the underlying buffered reader has bytes available.
// Returns (0, slice) on success — slice may be empty when the source
// is at EOF. (iobuf.Other, empty) is returned on an underlying error.
async fill_buf(r<u64>) (i32, iobuf.Buf) {
    fut<FillBuf> = FillBuf::new(r)
    fut.await
    if fut.out_err == runtime.PollError {
        return iobuf.Other, new iobuf.Buf { inner: null, len: 0 }
    }
    return 0, fut.out_buf
}

// Search [ptr, ptr+len) for `needle`. Returns the index of the first
// match, or -1 when no match exists.
fn buf_index_of(ptr<u8*>, len<u64>, needle<u8>) i64 {
    i<u64> = 0
    while i < len {
        if ptr[i.(i32)] == needle return i.(i64)
        i = i + 1
    }
    return -1
}

// Append `n` bytes starting at `src` into `dst`'s unfilled region.
// Caller guarantees dst.remaining() >= n.
fn read_buf_append(dst<aio.ReadBuf>, src<u8*>, n<u64>){
    base<u8*> = dst.inner.buf.inner + dst.filled.(i32)
    if n > 0 std.memcpy(base, src, n)
    dst.advance(n)
}

// Pull-style iterator that emits one record per `next` call, splitting
// the underlying buffered reader on byte `delim`. The trailing
// delimiter is *not* included in the emitted record.
mem Split {
    u64 r        // raw bits of an AsyncBufRead implementor
    u8  delim
    i32 done     // 1 once the source signalled EOF
}

// Build a Split iterator for buffered reader `r` and delimiter `delim`.
const Split::new(r<u64>, delim<u8>) Split {
    s<Split> = new Split
    s.r     = r
    s.delim = delim
    s.done  = 0
    return s
}

// Same shape as Split but specialised on LF; trailing CR is *not*
// trimmed by this layer (callers can drop it themselves).
mem Lines {
    u64 r
    i32 done
}

// Build a Lines iterator for buffered reader `r`.
const Lines::new(r<u64>) Lines {
    l<Lines> = new Lines
    l.r    = r
    l.done = 0
    return l
}

// Read the next delimited record into `dst`. Returns:
//   (0, n) on a successful record (delimiter consumed but not stored);
//   (0, n) on EOF where n > 0 — the trailing partial record;
//   (iobuf.UnexpectedEof, 0) when the iterator already finished;
//   (iobuf.Other, n) when an underlying fill_buf surfaced an error
//     (n is the number of bytes already accumulated into dst).
// `dst` running out of capacity is treated as an early return — the
// next call resumes scanning with a fresh dst from the caller.
async Split::next(dst<aio.ReadBuf>) (i32, u64) {
    if this.done return iobuf.UnexpectedEof, 0.(u64)
    total<u64> = 0
    loop {
        err<i32>, slice<iobuf.Buf> = fill_buf(this.r).await
        if err != 0 return iobuf.Other, total
        if slice.len() == 0 {
            // EOF — emit any partial record one last time, then latch.
            this.done = 1
            return 0, total
        }
        idx<i64> = buf_index_of(slice.inner, slice.len(), this.delim)
        if idx >= 0 {
            // Copy [0, idx) to dst, then consume idx+1 (drop delimiter).
            take<u64> = idx.(u64)
            if take > dst.remaining() take = dst.remaining()
            read_buf_append(dst, slice.inner, take)
            total = total + take
            this.r.(aio.AsyncBufRead).consume(idx.(u64) + 1)
            return 0, total
        }
        // No delimiter in this slice — copy what we can, consume,
        // repeat.
        take<u64> = slice.len()
        if take > dst.remaining() take = dst.remaining()
        read_buf_append(dst, slice.inner, take)
        total = total + take
        this.r.(aio.AsyncBufRead).consume(take)
        if dst.remaining() == 0 return 0, total
    }
}

// Read the next line into `dst`. Trailing LF is consumed but not stored;
// trailing CR is preserved (callers strip it as needed).
async Lines::next_line(dst<aio.ReadBuf>) (i32, u64) {
    if this.done return iobuf.UnexpectedEof, 0.(u64)
    inner<Split> = Split::new(this.r, LF)
    err<i32>, n<u64> = inner.next(dst).await
    this.done = inner.done
    return err, n
}
