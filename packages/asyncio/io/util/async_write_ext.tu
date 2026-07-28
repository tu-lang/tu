// AsyncWrite extension helpers. `Write` is a leaf future for one
// poll_write; `Flush` / `Shutdown` mirror the no-payload variants.
// `write_all` drives poll_write until every byte is committed.
//
// Leaf futures hold `AsyncWrite*` (RFC: api members must be pointers).
// Factories bind via `new T { w: bits.(AsyncWrite), ... }` — field
// assign `f.w = ...` after `new T` overwrites the async poll virf
// (InitApiVptr hits the holder). Remain / Write.buf are typed Buf nests.

use runtime
use io as iobuf

// Leaf future for a single AsyncWrite::poll_write call.
mem Write: async {
    AsyncWrite* w
    iobuf.Buf buf
}

const Write::new(w<AsyncWrite>, buf<iobuf.Buf>) Write {
    bits<u64> = 0
    bits = w
    return new Write {
        w: bits.(AsyncWrite),
        buf: buf
    }
}

Write::poll(ctx) {
    err<i32>, n<u64> = this.w.poll_write(ctx, this.buf)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        return runtime.PollReady, 0.(u64)
    }
    return runtime.PollReady, n
}

mem Flush: async {
    AsyncWrite* w
    i32 done
}

const Flush::new(w<AsyncWrite>) Flush {
    bits<u64> = 0
    bits = w
    return new Flush {
        w: bits.(AsyncWrite),
        done: 0
    }
}

Flush::poll(ctx) {
    err<i32> = this.w.poll_flush(ctx)
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
    AsyncWrite* w
    i32 done
}

const Shutdown::new(w<AsyncWrite>) Shutdown {
    bits<u64> = 0
    bits = w
    return new Shutdown {
        w: bits.(AsyncWrite),
        done: 0
    }
}

Shutdown::poll(ctx) {
    err<i32> = this.w.poll_shutdown(ctx)
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

fn write(w<AsyncWrite>, buf<iobuf.Buf>) Write {
    return Write::new(w, buf)
}

// Leaf future: write every byte of `buf`.
mem WriteAll: async {
    AsyncWrite* w
    iobuf.Buf remain
    i32 done_code
}

const WriteAll::new(w<AsyncWrite>, buf<iobuf.Buf>) WriteAll {
    bits<u64> = 0
    bits = w
    return new WriteAll {
        w: bits.(AsyncWrite),
        remain: buf,
        done_code: 0
    }
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
        st<i32>, n<u64> = this.w.poll_write(ctx, rem)
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

fn write_all(w<AsyncWrite>, buf<iobuf.Buf>) WriteAll {
    return WriteAll::new(w, buf)
}

fn flush(w<AsyncWrite>) Flush {
    return Flush::new(w)
}

fn shutdown(w<AsyncWrite>) Shutdown {
    return Shutdown::new(w)
}

fn write_u8(w<AsyncWrite>, v<u8>) WriteAll {
    tmp<iobuf.Buf> = iobuf.NewBuf(1)
    p<i8*> = tmp.ptr()
    p[0] = v.(i8)
    return WriteAll::new(w, tmp)
}

fn write_i8(w<AsyncWrite>, v<i8>) WriteAll {
    return write_u8(w, v.(u8))
}

fn write_u16(w<AsyncWrite>, v<u16>) WriteAll {
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

fn write_i16(w<AsyncWrite>, v<i16>) WriteAll {
    return write_u16(w, v.(u16))
}

fn write_u32(w<AsyncWrite>, v<u32>) WriteAll {
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

fn write_i32(w<AsyncWrite>, v<i32>) WriteAll {
    return write_u32(w, v.(u32))
}

fn write_u64(w<AsyncWrite>, v<u64>) WriteAll {
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

fn write_i64(w<AsyncWrite>, v<i64>) WriteAll {
    return write_u64(w, v.(u64))
}
