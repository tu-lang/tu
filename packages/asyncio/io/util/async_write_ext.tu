// AsyncWrite extension helpers. `Write` is a leaf future for one
// poll_write; `Flush` / `Shutdown` mirror the no-payload variants.
// `write_all` drives `Write` until every byte of the input slice is
// committed or an error short-circuits the loop.

use runtime
use io as iobuf
use asyncio.io as aio

// Leaf future for a single AsyncWrite::poll_write call. `w` carries
// the raw bits of an AsyncWrite implementor (cast on each poll); `buf`
// is the source slice. PollReady payload is the number of bytes the
// underlying write accepted.
mem Write: async {
    u64       w     // raw bits of an AsyncWrite implementor
    iobuf.Buf buf   // source slice (not owned)
}

// Build a Write leaf future targeting writer `w` with source `buf`.
const Write::new(w<u64>, buf<iobuf.Buf>) Write {
    f<Write> = new Write
    f.w   = w
    f.buf = buf
    return f
}

// Drive one poll_write against the sink. Returns runtime.PollPending,
// or (runtime.PollReady, n) where n is bytes accepted this poll.
// PollError surfaces as (PollReady, 0) so write_all can detect a stall
// and convert it to io.WriteZero.
Write::poll(ctx) {
    err<i32>, n<u64> = this.w.(aio.AsyncWrite).poll_write(ctx, this.buf)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        return runtime.PollReady, 0.(u64)
    }
    return runtime.PollReady, n
}

// Leaf future for a single AsyncWrite::poll_flush call.
mem Flush: async {
    u64 w
    i32 done    // 0 = pending, 1 = ready, 2 = error (latched once)
}

// Build a Flush leaf future targeting writer `w`.
const Flush::new(w<u64>) Flush {
    f<Flush> = new Flush
    f.w    = w
    f.done = 0
    return f
}

// Drive one poll_flush. PollPending propagates; PollReady completes
// with `done = 1`; PollError completes with `done = 2` so the helper
// can distinguish a clean flush from a transport failure.
Flush::poll(ctx) {
    err<i32> = this.w.(aio.AsyncWrite).poll_flush(ctx)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        this.done = 2
        return runtime.PollReady, 0.(u64)
    }
    this.done = 1
    return runtime.PollReady, 0.(u64)
}

// Leaf future for a single AsyncWrite::poll_shutdown call. Same
// completion semantics as Flush.
mem Shutdown: async {
    u64 w
    i32 done    // 0 = pending, 1 = ready, 2 = error
}

// Build a Shutdown leaf future targeting writer `w`.
const Shutdown::new(w<u64>) Shutdown {
    f<Shutdown> = new Shutdown
    f.w    = w
    f.done = 0
    return f
}

// Drive one poll_shutdown.
Shutdown::poll(ctx) {
    err<i32> = this.w.(aio.AsyncWrite).poll_shutdown(ctx)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        this.done = 2
        return runtime.PollReady, 0.(u64)
    }
    this.done = 1
    return runtime.PollReady, 0.(u64)
}

// Write at most one chunk from `buf`. Returns (0, n) where n is the
// number of bytes the underlying writer accepted. n == 0 typically
// indicates a writer-side stall; callers should treat repeated zero
// returns as io.WriteZero.
async write(w<u64>, buf<iobuf.Buf>) (i32, u64) {
    fut<Write> = Write::new(w, buf)
    n<u64> = fut.await
    return 0, n
}

// Write the entire `buf` to `w`. Returns 0 when every byte landed,
// io.WriteZero if the underlying writer ever accepts zero bytes
// without yielding (which would otherwise spin forever).
async write_all(w<u64>, buf<iobuf.Buf>) i32 {
    rest<iobuf.Buf> = buf
    while rest.len() > 0 {
        fut<Write> = Write::new(w, rest)
        n<u64> = fut.await
        if n == 0 return iobuf.WriteZero
        // Slice the unwritten tail; split_at returns (head, tail) at mid.
        head<iobuf.Buf>, tail<iobuf.Buf> = rest.split_at(n)
        rest = tail
    }
    return 0
}

// Flush the writer. Returns 0 on success, io.Other on a poll_flush
// error (the underlying error code is currently swallowed by the leaf
// — this matches the read-side convention until poll_flush gains a
// secondary error channel).
async flush(w<u64>) i32 {
    fut<Flush> = Flush::new(w)
    fut.await
    if fut.done == 2 return iobuf.Other
    return 0
}

// Shut the writer down. Same return convention as flush.
async shutdown(w<u64>) i32 {
    fut<Shutdown> = Shutdown::new(w)
    fut.await
    if fut.done == 2 return iobuf.Other
    return 0
}

// ---------------------------------------------------------------------
// Big-endian integer writers. Each helper packs the value into a small
// temporary Buf, then drives write_all to commit it. On write failure
// the underlying error code is propagated.
// ---------------------------------------------------------------------

// Write one byte as u8.
async write_u8(w<u64>, v<u8>) i32 {
    tmp<iobuf.Buf> = iobuf.NewBuf(1)
    tmp.inner[0] = v
    return write_all(w, tmp).await
}

// Write one byte as i8 (raw two's-complement bits).
async write_i8(w<u64>, v<i8>) i32 {
    return write_u8(w, v.(u8)).await
}

// Write two bytes as u16, big-endian.
async write_u16(w<u64>, v<u16>) i32 {
    tmp<iobuf.Buf> = iobuf.NewBuf(2)
    tmp.inner[0] = ((v >> 8) & 0xFF).(u8)
    tmp.inner[1] = (v & 0xFF).(u8)
    return write_all(w, tmp).await
}

// Write two bytes as i16, big-endian.
async write_i16(w<u64>, v<i16>) i32 {
    return write_u16(w, v.(u16)).await
}

// Write four bytes as u32, big-endian.
async write_u32(w<u64>, v<u32>) i32 {
    tmp<iobuf.Buf> = iobuf.NewBuf(4)
    tmp.inner[0] = ((v >> 24) & 0xFF).(u8)
    tmp.inner[1] = ((v >> 16) & 0xFF).(u8)
    tmp.inner[2] = ((v >> 8)  & 0xFF).(u8)
    tmp.inner[3] = ( v        & 0xFF).(u8)
    return write_all(w, tmp).await
}

// Write four bytes as i32, big-endian.
async write_i32(w<u64>, v<i32>) i32 {
    return write_u32(w, v.(u32)).await
}

// Write eight bytes as u64, big-endian.
async write_u64(w<u64>, v<u64>) i32 {
    tmp<iobuf.Buf> = iobuf.NewBuf(8)
    i<i32> = 0
    for(; i < 8; i += 1){
        shift<i32> = (7 - i) * 8
        tmp.inner[i] = ((v >> shift) & 0xFF).(u8)
    }
    return write_all(w, tmp).await
}

// Write eight bytes as i64, big-endian.
async write_i64(w<u64>, v<i64>) i32 {
    return write_u64(w, v.(u64)).await
}
