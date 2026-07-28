// AsyncWrite extension helpers. `Write` is a leaf future for one
// poll_write; `Flush` / `Shutdown` mirror the no-payload variants.
// `write_all` drives poll_write until every byte is committed.
//
// Factories take typed `aio.AsyncWrite` (vtable dispatch). Leaf futures
// store the implementor as u64 bits so async frames stay GC-safe.
// Poll paths use u64 bits + tyassert dispatch (InitApiVptr only on assign/new).
// Writer slot stays u64 bits so the async frame stays representation-neutral;
// remain is a typed `iobuf.Buf` value nest (api-impl mems reserve offset-0;
// full sizeof payload copy is correct — see design async-value-nest-api-slot).

use runtime
use io as iobuf
use asyncio.io as aio

// Leaf future for a single AsyncWrite::poll_write call.
mem Write: async {
    u64 w
    u64 buf_bits
}

const Write::new(w<u64>, buf<iobuf.Buf>) Write {
    f<Write> = new Write
    f.w = w
    f.buf_bits = iobuf.buf_to_bits(buf)
    return f
}

Write::poll(ctx) {
    err<i32>, n<u64> = this.w.(aio.AsyncWrite).poll_write(ctx, this.buf_bits)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        return runtime.PollReady, 0.(u64)
    }
    return runtime.PollReady, n
}

mem Flush: async {
    u64 w
    i32 done
}

const Flush::new(w<u64>) Flush {
    f<Flush> = new Flush
    f.w = w
    f.done = 0
    return f
}

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

mem Shutdown: async {
    u64 w
    i32 done
}

const Shutdown::new(w<u64>) Shutdown {
    f<Shutdown> = new Shutdown
    f.w = w
    f.done = 0
    return f
}

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

fn writer_bits(w<aio.AsyncWrite>) u64 {
    bits<u64> = 0
    bits = w
    return bits
}

fn write(w<aio.AsyncWrite>, buf<iobuf.Buf>) Write {
    return Write::new(writer_bits(w), buf)
}

// Leaf future: write every byte of `buf`.
mem WriteAll: async {
    u64 w_bits
    iobuf.Buf remain
    i32 done_code
}

const WriteAll::new(w<u64>, buf<iobuf.Buf>) WriteAll {
    f<WriteAll> = new WriteAll
    f.w_bits = w
    f.remain = buf
    f.done_code = 0
    return f
}

WriteAll::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    wz<i32> = 16908312
    ok_code<i32> = 1
    code<i32> = this.done_code
    if code != 0 {
        return ready, code
    }
    rem<iobuf.Buf> = this.remain
    while iobuf.buf_len(rem) > 0 {
        bits<u64> = iobuf.buf_to_bits(rem)
        st<i32>, n<u64> = this.w_bits.(aio.AsyncWrite).poll_write(ctx, bits)
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
        this.remain = rem
    }
    return ready, ok_code
}

fn write_all(w<aio.AsyncWrite>, buf<iobuf.Buf>) WriteAll {
    return WriteAll::new(writer_bits(w), buf)
}

fn flush(w<aio.AsyncWrite>) Flush {
    return Flush::new(writer_bits(w))
}

fn shutdown(w<aio.AsyncWrite>) Shutdown {
    return Shutdown::new(writer_bits(w))
}

fn write_u8(w<aio.AsyncWrite>, v<u8>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(1)
    p<i8*> = tmp.ptr()
    p[0] = v.(i8)
    return WriteAll::new(writer_bits(w), tmp)
}

fn write_i8(w<aio.AsyncWrite>, v<i8>) WriteAll {
    return write_u8(w, v.(u8))
}

fn write_u16(w<aio.AsyncWrite>, v<u16>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(2)
    p<i8*> = tmp.ptr()
    hi<u32> = (v >> 8) & 0xFF
    lo<u32> = v & 0xFF
    b0<u8> = hi.(u8)
    b1<u8> = lo.(u8)
    p[0] = b0.(i8)
    p[1] = b1.(i8)
    return WriteAll::new(writer_bits(w), tmp)
}

fn write_i16(w<aio.AsyncWrite>, v<i16>) WriteAll {
    return write_u16(w, v.(u16))
}

fn write_u32(w<aio.AsyncWrite>, v<u32>) WriteAll {
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
    return WriteAll::new(writer_bits(w), tmp)
}

fn write_i32(w<aio.AsyncWrite>, v<i32>) WriteAll {
    return write_u32(w, v.(u32))
}

fn write_u64(w<aio.AsyncWrite>, v<u64>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(8)
    p<i8*> = tmp.ptr()
    for i<i32> = 0 ; i < 8 ; i += 1 {
        shift<i32> = (7 - i) * 8
        b<u64> = (v >> shift) & 0xFF
        bu<u8> = b.(u8)
        p[i] = bu.(i8)
    }
    return WriteAll::new(writer_bits(w), tmp)
}

fn write_i64(w<aio.AsyncWrite>, v<i64>) WriteAll {
    return write_u64(w, v.(u64))
}
