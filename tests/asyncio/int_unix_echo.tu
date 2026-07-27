// Integration test (task 15.17): Unix-domain stream echo round-trip.
// Leaf futures + io.* error conventions; see asyncio-conventions optimize doc.

use fmt
use os
use io
use string
use std
use sys
use runtime
use asyncio.runtime as rt
use asyncio.net.unix as unix

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

mem EchoWriteAll: async {
    unix.UnixStream* stream
    u64              remain_bits
    i32              done_code
}

const EchoWriteAll::new(s<unix.UnixStream>, buf<io.Buf>) EchoWriteAll {
    f<EchoWriteAll> = new EchoWriteAll
    f.stream = s
    f.remain_bits = io.buf_to_bits(buf)
    f.done_code = 0
    return f
}

EchoWriteAll::poll(ctx) {
    if this.done_code != 0 {
        return runtime.PollReady, this.done_code
    }
    rem<io.Buf> = io.buf_from_bits(this.remain_bits)
    while io.buf_len(rem) > 0 {
        bits<u64> = io.buf_to_bits(rem)
        st<i32>, n<u64> = unix.stream_poll_write(this.stream, ctx, bits)
        if st == runtime.PollPending {
            this.remain_bits = bits
            return runtime.PollPending
        }
        if st == runtime.PollError || n == 0 {
            this.done_code = io.WriteZero
            return runtime.PollReady, io.WriteZero
        }
        rem = io.buf_slice(rem, n)
        this.remain_bits = io.buf_to_bits(rem)
    }
    return runtime.PollReady, io.Ok
}

mem EchoRead: async {
    unix.UnixStream* stream
    u64              buf_bits
}

const EchoRead::new(s<unix.UnixStream>, buf<io.Buf>) EchoRead {
    f<EchoRead> = new EchoRead
    f.stream = s
    f.buf_bits = io.buf_to_bits(buf)
    return f
}

EchoRead::poll(ctx) {
    st<i32>, n<u64> = unix.stream_poll_read_buf(this.stream, ctx, this.buf_bits)
    if st == runtime.PollPending {
        return runtime.PollPending
    }
    if st == runtime.PollError {
        return runtime.PollReady, io.Uncategorized, 0.(u64)
    }
    return runtime.PollReady, io.Ok, n
}

async unix_echo_body() {
    path<string.String> = string.S(*"/tmp/asyncio_int_unix_echo.sock")
    sys.unlink(path.str())

    berr<i32>, lbits<u64> = unix.unix_listener_bind_bits(path)
    if berr != io.Ok return berr
    listener<unix.UnixListener> = lbits.(unix.UnixListener)
    if listener == null return io.Other

    cerr<i32>, client<unix.UnixStream> = unix.UnixStream::connect(path).await
    if cerr != io.Ok return cerr

    aerr<i32>, server<unix.UnixStream> = listener.accept().await
    if aerr != io.Ok return aerr

    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())
    mlen_u<u64> = mlen.(u64)

    werr<i32> = EchoWriteAll::new(client, str_buf(msg)).await
    if werr != io.Ok return werr

    own1<io.Buf> = io.NewBuf(16)
    rerr<i32>, rn<u64> = EchoRead::new(server, own1).await
    if rerr != io.Ok return rerr
    if rn != mlen_u return io.OtherParse

    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    werr2<i32> = EchoWriteAll::new(server, echo).await
    if werr2 != io.Ok return werr2

    own2<io.Buf> = io.NewBuf(16)
    rerr2<i32>, n2<u64> = EchoRead::new(client, own2).await
    if rerr2 != io.Ok return rerr2
    if n2 != mlen_u return io.OtherParse

    src<u8*> = msg.str()
    got_p<i8*> = own2.ptr()
    got<u8*> = null
    got = got_p
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_unix_echo() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, unix_echo_body(), 0)
    if rerr != 0 {
        os.dief("block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("unix echo body failed: %d", ri)
    }
    fmt.println("int_unix_echo passed")
}

fn main() {
    int_unix_echo()
}
