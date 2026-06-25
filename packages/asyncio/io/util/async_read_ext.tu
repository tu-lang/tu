// AsyncRead extension helpers. `Read` is a leaf future for one
// poll_read call; `read_exact` and `read_to_end` drive the underlying
// AsyncRead in a loop until their contracts are met.

use runtime
use io as iobuf
use asyncio.io as aio

// Leaf future for a single AsyncRead::poll_read call. `r` carries the
// raw bits of the AsyncRead implementor (cast via r.(aio.AsyncRead) on
// each poll); `buf` is the destination ReadBuf. PollReady result is the
// number of bytes that landed during this poll (delta of buf.filled).
mem Read: async {
    u64           r          // raw bits of an AsyncRead implementor
    aio.ReadBuf*  buf        // destination read buffer (not owned)
    u64           start      // buf.filled snapshot at first poll entry
    i32           started    // 0 = need to record start, 1 = recorded
}

// Build a Read leaf future targeting reader `r` with destination `buf`.
const Read::new(r<u64>, buf<aio.ReadBuf>) Read {
    f<Read> = new Read
    f.r       = r
    f.buf     = buf
    f.start   = 0
    f.started = 0
    return f
}

// Drive one poll_read against the source. Returns runtime.PollPending,
// or (runtime.PollReady, n_delta) where n_delta = buf.filled - start.
// On runtime.PollError the leaf surfaces (PollReady, 0) so callers can
// detect failure via sustained zero-byte returns; the `read_exact` and
// `read_to_end` helpers convert that into proper error codes.
Read::poll(ctx) {
    if this.started == 0 {
        this.start   = this.buf.filled_len()
        this.started = 1
    }
    err<i32> = this.r.(aio.AsyncRead).poll_read(ctx, this.buf)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        return runtime.PollReady, 0.(u64)
    }
    delta<u64> = this.buf.filled_len() - this.start
    return runtime.PollReady, delta
}

// Read at most one chunk into `buf`. Returns (0, n) where n is the
// number of bytes that landed during this call. `n == 0` denotes EOF.
async read(r<u64>, buf<aio.ReadBuf>) (i32, u64) {
    fut<Read> = Read::new(r, buf)
    n<u64> = fut.await
    return 0, n
}

// Read until `buf` is filled exactly to capacity. Returns 0 on full
// fill, or io.UnexpectedEof if the source stopped producing bytes
// before the buffer was full.
async read_exact(r<u64>, buf<aio.ReadBuf>) i32 {
    while buf.remaining() > 0 {
        before<u64> = buf.filled_len()
        fut<Read> = Read::new(r, buf)
        fut.await
        // Zero-byte progress means EOF (or a poll_read error swallowed
        // by the leaf); either way we cannot satisfy the exact contract.
        if buf.filled_len() == before {
            return iobuf.UnexpectedEof
        }
    }
    return 0
}

// Read into `buf` until EOF or until `buf` is full. Returns
// (0, total_bytes_read). When the buffer fills before EOF the call
// stops early; higher-level helpers grow the underlying Buffer as
// needed.
async read_to_end(r<u64>, buf<aio.ReadBuf>) (i32, u64) {
    total<u64> = 0
    loop {
        if buf.remaining() == 0 break
        before<u64> = buf.filled_len()
        fut<Read> = Read::new(r, buf)
        fut.await
        delta<u64> = buf.filled_len() - before
        total = total + delta
        if delta == 0 break
    }
    return 0, total
}

// Newline byte for read_line. Tracked as a u8 constant so callers do not
// have to think about the i8/u8 distinction of character literals.
LF<u8> = 10

// Append a single byte to `dst`. Caller must ensure dst.remaining() > 0.
// Writes through the unfilled head of the backing Buf and advances the
// filled cursor by one.
fn read_buf_push_byte(dst<aio.ReadBuf>, byte<u8>){
    base<u8*> = dst.inner.buf.inner
    pos<i32>  = dst.filled.(i32)
    base[pos] = byte
    dst.advance(1)
}

// Validate that [ptr, ptr+len) is a well-formed UTF-8 byte sequence.
// Returns 0 on success, iobuf.InvalidData on the first invalid lead or
// continuation byte. The matcher is the standard 4-class state machine
// (1/2/3/4 byte sequences); overlong / surrogate ranges are not
// rejected at this layer because we do not maintain a full DFA — the
// goal is to guard against obviously truncated or non-UTF-8 input
// from network / disk sources.
fn validate_utf8(ptr<u8*>, len<u64>) i32 {
    i<u64> = 0
    while i < len {
        b<u8>      = ptr[i.(i32)]
        extra<i32> = 0
        if (b & 0x80) == 0 {
            extra = 0
        } else if (b & 0xE0) == 0xC0 {
            extra = 1
        } else if (b & 0xF0) == 0xE0 {
            extra = 2
        } else if (b & 0xF8) == 0xF0 {
            extra = 3
        } else {
            return iobuf.InvalidData
        }
        if (i + extra.(u64)) >= len return iobuf.InvalidData
        j<i32> = 1
        for(; j <= extra; j += 1){
            cb<u8> = ptr[i.(i32) + j]
            if (cb & 0xC0) != 0x80 return iobuf.InvalidData
        }
        i = i + 1 + extra.(u64)
    }
    return 0
}

// Read bytes from `r` into `dst` until `delim` is encountered (inclusive),
// EOF is reached, or `dst` runs out of capacity. Returns (0, n) where n
// is the number of bytes appended during this call. Reading is performed
// one byte at a time; for higher throughput use a BufReader-backed
// AsyncBufReadExt::read_until once available.
async read_until(r<u64>, delim<u8>, dst<aio.ReadBuf>) (i32, u64) {
    total<u64> = 0
    loop {
        if dst.remaining() == 0 break
        // Pull exactly one byte via a fresh 1-byte ReadBuf so the source
        // cannot over-deliver past the delimiter.
        one<iobuf.Buf>          = iobuf.NewBuf(1)
        one_buffer<iobuf.Buffer> = iobuf.Buffer::from_uinit(one)
        rb<aio.ReadBuf>         = aio.ReadBuf::new(one_buffer)
        fut<Read>               = Read::new(r, rb)
        n<u64>                  = fut.await
        if n == 0 break
        b<u8> = one.inner[0]
        read_buf_push_byte(dst, b)
        total = total + 1
        if b == delim break
    }
    return 0, total
}

// Read bytes from `r` into `dst` until LF, EOF, or dst is full. Thin
// wrapper over read_until with delim = '\n'. CRLF is not trimmed.
async read_line(r<u64>, dst<aio.ReadBuf>) (i32, u64) {
    err<i32>, n<u64> = read_until(r, LF, dst).await
    return err, n
}

// Read all remaining bytes from `r` into `dst` and validate the newly
// appended region as UTF-8. Returns (0, n) on success, (iobuf.InvalidData,
// n) when the appended bytes are not valid UTF-8, or whatever non-zero
// error code read_to_end surfaced.
async read_to_string(r<u64>, dst<aio.ReadBuf>) (i32, u64) {
    before<u64>      = dst.filled_len()
    err<i32>, n<u64> = read_to_end(r, dst).await
    if err != 0 return err, n
    base<u8*> = dst.inner.buf.inner + before.(i32)
    if validate_utf8(base, n) != 0 return iobuf.InvalidData, n
    return 0, n
}

// ---------------------------------------------------------------------
// Big-endian integer readers. Each helper allocates a small temporary
// Buf, drives read_exact to fill it, then assembles the value MSB-first.
// On read_exact failure the helper forwards the error code with a zero
// payload.
// ---------------------------------------------------------------------

// Read one byte as u8.
async read_u8(r<u64>) (i32, u8) {
    tmp<iobuf.Buf>          = iobuf.NewBuf(1)
    tmp_buffer<iobuf.Buffer> = iobuf.Buffer::from_uinit(tmp)
    rb<aio.ReadBuf>         = aio.ReadBuf::new(tmp_buffer)
    err<i32> = read_exact(r, rb).await
    if err != 0 return err, 0.(u8)
    return 0, tmp.inner[0]
}

// Read one byte as i8 (two's-complement reinterpretation of read_u8).
async read_i8(r<u64>) (i32, i8) {
    err<i32>, v<u8> = read_u8(r).await
    if err != 0 return err, 0.(i8)
    return 0, v.(i8)
}

// Read two bytes as u16, big-endian.
async read_u16(r<u64>) (i32, u16) {
    tmp<iobuf.Buf>          = iobuf.NewBuf(2)
    tmp_buffer<iobuf.Buffer> = iobuf.Buffer::from_uinit(tmp)
    rb<aio.ReadBuf>         = aio.ReadBuf::new(tmp_buffer)
    err<i32> = read_exact(r, rb).await
    if err != 0 return err, 0.(u16)
    b0<u16> = tmp.inner[0].(u16)
    b1<u16> = tmp.inner[1].(u16)
    return 0, (b0 << 8) | b1
}

// Read two bytes as i16, big-endian.
async read_i16(r<u64>) (i32, i16) {
    err<i32>, v<u16> = read_u16(r).await
    if err != 0 return err, 0.(i16)
    return 0, v.(i16)
}

// Read four bytes as u32, big-endian.
async read_u32(r<u64>) (i32, u32) {
    tmp<iobuf.Buf>          = iobuf.NewBuf(4)
    tmp_buffer<iobuf.Buffer> = iobuf.Buffer::from_uinit(tmp)
    rb<aio.ReadBuf>         = aio.ReadBuf::new(tmp_buffer)
    err<i32> = read_exact(r, rb).await
    if err != 0 return err, 0.(u32)
    b0<u32> = tmp.inner[0].(u32)
    b1<u32> = tmp.inner[1].(u32)
    b2<u32> = tmp.inner[2].(u32)
    b3<u32> = tmp.inner[3].(u32)
    return 0, (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
}

// Read four bytes as i32, big-endian.
async read_i32(r<u64>) (i32, i32) {
    err<i32>, v<u32> = read_u32(r).await
    if err != 0 return err, 0
    return 0, v.(i32)
}

// Read eight bytes as u64, big-endian.
async read_u64(r<u64>) (i32, u64) {
    tmp<iobuf.Buf>          = iobuf.NewBuf(8)
    tmp_buffer<iobuf.Buffer> = iobuf.Buffer::from_uinit(tmp)
    rb<aio.ReadBuf>         = aio.ReadBuf::new(tmp_buffer)
    err<i32> = read_exact(r, rb).await
    if err != 0 return err, 0.(u64)
    acc<u64> = 0
    i<i32> = 0
    for(; i < 8; i += 1){
        acc = (acc << 8) | tmp.inner[i].(u64)
    }
    return 0, acc
}

// Read eight bytes as i64, big-endian.
async read_i64(r<u64>) (i32, i64) {
    err<i32>, v<u64> = read_u64(r).await
    if err != 0 return err, 0.(i64)
    return 0, v.(i64)
}
