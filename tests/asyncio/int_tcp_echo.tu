// Integration test (task 15.16): TCP echo round-trip over asyncio.net.tcp.
// Leaf futures use static member dispatch (stream_poll_*). Conventions: see
// co/docs/optimize/2026-07-27-asyncio-conventions.md.

use fmt
use os
use io
use string
use std
use net
use runtime
use asyncio.runtime as rt
use asyncio.net as anet
use asyncio.net.tcp as tcp
use asyncio.time as atime

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

// Compare first nbytes of buf to string (caller must verify nbytes).
fn cmp_buf_eq(got<io.Buf>, want_s<string.String>, nbytes<u64>) i32 {
    src<u8*> = want_s.str()
    gp<i8*> = got.ptr()
    g<u8*> = null
    g = gp
    i<u64> = 0
    while i < nbytes {
        if g[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

// WriteAll leaf over a concrete TcpStream.
mem EchoWriteAll: async {
    tcp.TcpStream* stream
    u64            remain_bits
    i32            done_code
}

const EchoWriteAll::new(s<tcp.TcpStream>, buf<io.Buf>) EchoWriteAll {
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
        st<i32>, n<u64> = tcp.stream_poll_write(this.stream, ctx, bits)
        if st == runtime.PollPending {
            this.remain_bits = bits
            return runtime.PollPending
        }
        if st == runtime.PollError || n == 0 {
            this.done_code = io.WriteZero
            return runtime.PollReady, io.WriteZero
        }
        head<io.Buf>, tail<io.Buf> = rem.split_at(n)
        rem = tail
        this.remain_bits = io.buf_to_bits(rem)
    }
    return runtime.PollReady, io.Ok
}

// Read leaf into io.Buf (bits); await yields (err, nbytes).
mem EchoRead: async {
    tcp.TcpStream* stream
    u64            buf_bits
}

const EchoRead::new(s<tcp.TcpStream>, buf<io.Buf>) EchoRead {
    f<EchoRead> = new EchoRead
    f.stream = s
    f.buf_bits = io.buf_to_bits(buf)
    return f
}

EchoRead::poll(ctx) {
    st<i32>, n<u64> = tcp.stream_poll_read_buf(this.stream, ctx, this.buf_bits)
    if st == runtime.PollPending {
        return runtime.PollPending
    }
    if st == runtime.PollError {
        return runtime.PollReady, io.Uncategorized, 0.(u64)
    }
    return runtime.PollReady, io.Ok, n
}

async tcp_echo_body() {
    addr_s<string.String> = string.S(*"127.0.0.1:34567")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr_bits<u64> = anet.parse_socket_addr(addr_s.str(), slen)
    if perr != io.Ok return perr
    addr<net.SocketAddr> = addr_bits.(net.SocketAddr)

    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok return berr

    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok return cerr

    aerr<i32>, server<tcp.TcpStream> = listener.accept().await
    if aerr != io.Ok return aerr

    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())
    mlen_u<u64> = mlen.(u64)
    wbuf<io.Buf> = str_buf(msg)

    werr<i32> = EchoWriteAll::new(client, wbuf).await
    if werr != io.Ok return werr

    own1<io.Buf> = io.NewBuf(16)
    rerr<i32>, rn<u64> = EchoRead::new(server, own1).await
    if rerr != io.Ok return rerr
    if rn != mlen_u return io.OtherParse
    cmp_err<i32> = cmp_buf_eq(own1, msg, rn)
    if cmp_err != io.Ok return cmp_err

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
    cmp_err2<i32> = cmp_buf_eq(own2, msg, n2)
    if cmp_err2 != io.Ok return cmp_err2

    hold_err<i32> = atime.sleep(atime.from_millis(50)).await
    if hold_err != io.Ok return hold_err

    return io.Ok
}

fn int_tcp_echo() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    body<runtime.Future> = tcp_echo_body()
    if body == null {
        os.die("tcp_echo_body returned null future")
    }
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 {
        os.dief("block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("tcp_echo body failed: %d", ri)
    }
    fmt.println("int_tcp_echo passed")
}

fn main() {
    int_tcp_echo()
}
