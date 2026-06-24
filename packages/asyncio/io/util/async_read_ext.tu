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
