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
    bits<u64> = iobuf.buf_to_bits(this.buf)
    err<i32>, n<u64> = this.w.(aio.AsyncWrite).poll_write(ctx, bits)
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

// The design write(): sync factory returning Write leaf (await at call site).
fn write(w<u64>, buf<iobuf.Buf>) Write {
    return Write::new(w, buf)
}

// Leaf future: write every byte of `buf`.
mem WriteAll: async {
    u64       writer_bits
    iobuf.Buf remain
    i32       done_code // latched error; 0 while in progress
}

const WriteAll::new(w<u64>, buf<iobuf.Buf>) WriteAll {
    f<WriteAll> = new WriteAll
    f.writer_bits = w
    f.remain = buf
    f.done_code = 0
    return f
}

// The design WriteAll::poll — keep issuing poll_write until remain is empty.
WriteAll::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    wz<i32> = iobuf.WriteZero
    code<i32> = this.done_code
    if code != 0 {
        return ready, code
    }
    rem<iobuf.Buf> = this.remain
    while rem.len() > 0 {
        bits<u64> = iobuf.buf_to_bits(rem)
        st<i32>, n<u64> = this.writer_bits.(aio.AsyncWrite).poll_write(ctx, bits)
        if st == pend {
            this.remain = rem
            return pend
        }
        if st == runtime.PollError || n == 0 {
            this.done_code = wz
            return ready, wz
        }
        head<iobuf.Buf>, tail<iobuf.Buf> = rem.split_at(n)
        rem = tail
    }
    this.remain = rem
    return ready, 0.(i64)
}

// The design write_all(): sync factory returning WriteAll leaf.
fn write_all(w<u64>, buf<iobuf.Buf>) WriteAll {
    return WriteAll::new(w, buf)
}

fn flush(w<u64>) Flush {
    return Flush::new(w)
}

fn shutdown(w<u64>) Shutdown {
    return Shutdown::new(w)
}

// Big-endian integer writers — return WriteAll leaves.
fn write_u8(w<u64>, v<u8>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(1)
    p<i8*> = tmp.ptr()
    p[0] = v.(i8)
    return WriteAll::new(w, tmp)
}

fn write_i8(w<u64>, v<i8>) WriteAll {
    return write_u8(w, v.(u8))
}

fn write_u16(w<u64>, v<u16>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(2)
    p<i8*> = tmp.ptr()
    hi<u32> = (v >> 8) & 0xFF
    lo<u32> = v & 0xFF
    b0<u8> = hi.(u8)
    b1<u8> = lo.(u8)
    p[0] = b0.(i8)
    p[1] = b1.(i8)
    return WriteAll::new(w, tmp)
}

fn write_i16(w<u64>, v<i16>) WriteAll {
    return write_u16(w, v.(u16))
}

fn write_u32(w<u64>, v<u32>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(4)
    p<i8*> = tmp.ptr()
    w0<u32> = (v >> 24) & 0xFF
    w1<u32> = (v >> 16) & 0xFF
    w2<u32> = (v >> 8) & 0xFF
    w3<u32> = v & 0xFF
    b0<u8> = w0.(u8)
    b1<u8> = w1.(u8)
    b2<u8> = w2.(u8)
    b3<u8> = w3.(u8)
    p[0] = b0.(i8)
    p[1] = b1.(i8)
    p[2] = b2.(i8)
    p[3] = b3.(i8)
    return WriteAll::new(w, tmp)
}

fn write_i32(w<u64>, v<i32>) WriteAll {
    return write_u32(w, v.(u32))
}

fn write_u64(w<u64>, v<u64>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(8)
    p<i8*> = tmp.ptr()
    for i<i32> = 0 ; i < 8 ; i += 1 {
        shift<i32> = (7 - i) * 8
        b<u64> = (v >> shift) & 0xFF
        bu<u8> = b.(u8)
        p[i] = bu.(i8)
    }
    return WriteAll::new(w, tmp)
}

fn write_i64(w<u64>, v<i64>) WriteAll {
    return write_u64(w, v.(u64))
}
