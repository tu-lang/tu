// Integration test (task 15.16): TCP echo round-trip over asyncio.net.tcp.
// Uses TcpStream::poll_read / poll_write via local leaf futures (static
// member dispatch). Avoids asyncio.io.util's `u64.(AsyncRead).poll_*` path,
 // which currently codegen's a lea of the missing api-method symbol instead
// of vtable dyn-dispatch.

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
use asyncio.io as aio

fn make_read_buf(cap<i32>) aio.ReadBuf {
    b<io.Buf> = io.NewBuf(cap)
    return aio.ReadBuf::from_ptr(b.ptr(), cap.(u64))
}

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    std.memcpy(b.ptr(), s.str(), slen.(u64))
    return b
}

// WriteAll leaf over a concrete TcpStream (mother: tokio::io::WriteAll).
mem EchoWriteAll: async {
    tcp.TcpStream* stream
    io.Buf         remain
    i32            done_code
}

const EchoWriteAll::new(s<tcp.TcpStream>, buf<io.Buf>) EchoWriteAll {
    f<EchoWriteAll> = new EchoWriteAll
    f.stream = s
    f.remain = buf
    f.done_code = 0
    return f
}

EchoWriteAll::poll(ctx) {
    ready<i32> = runtime.PollReady
    pend<i32> = runtime.PollPending
    wz<i32> = 16908312
    if this.done_code != 0 {
        return ready, this.done_code
    }
    rem<io.Buf> = this.remain
    while rem.len() > 0 {
        bits<u64> = io.buf_to_bits(rem)
        st<i32>, n<u64> = this.stream.poll_write(ctx, bits)
        if st == pend {
            this.remain = rem
            return pend
        }
        if st == runtime.PollError || n == 0 {
            this.done_code = wz
            return ready, wz
        }
        head<io.Buf>, tail<io.Buf> = rem.split_at(n)
        rem = tail
    }
    this.remain = rem
    return ready, 0.(i64)
}

// Read leaf over a concrete TcpStream (mother: tokio::io::Read).
mem EchoRead: async {
    tcp.TcpStream* stream
    aio.ReadBuf*   buf
    u64            start
    i32            started
}

const EchoRead::new(s<tcp.TcpStream>, buf<aio.ReadBuf>) EchoRead {
    f<EchoRead> = new EchoRead
    f.stream = s
    f.buf = buf
    f.start = 0
    f.started = 0
    return f
}

EchoRead::poll(ctx) {
    if this.started == 0 {
        this.start = this.buf.filled_len()
        this.started = 1
    }
    err<i32> = this.stream.poll_read(ctx, this.buf)
    if err == runtime.PollPending {
        return runtime.PollPending
    }
    if err == runtime.PollError {
        return runtime.PollReady, 1.(i64), 0.(u64)
    }
    delta<u64> = this.buf.filled_len() - this.start
    return runtime.PollReady, 0.(i64), delta
}

async tcp_echo_body() {
    addr_s<string.String> = string.S(*"127.0.0.1:34567")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr_bits<u64> = anet.parse_socket_addr(addr_s.str(), slen)
    if perr != io.Ok return perr
    addr<net.SocketAddr> = addr_bits.(net.SocketAddr)

    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok return berr

    cfut<tcp.ConnectFut> = tcp.TcpStream::connect(addr)
    cerr<i32>, client<tcp.TcpStream> = cfut.await
    if cerr != io.Ok return cerr

    aerr2<i32>, server<tcp.TcpStream> = listener.accept().await
    if aerr2 != io.Ok return aerr2

    msg<string.String> = string.S(*"ping")
    wfut<EchoWriteAll> = EchoWriteAll::new(client, str_buf(msg))
    werr<i32> = wfut.await
    if werr != io.Ok return werr

    rbuf<aio.ReadBuf> = make_read_buf(16)
    rfut<EchoRead> = EchoRead::new(server, rbuf)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok return rerr
    mlen<i32> = std.strlen(msg.str())
    if rn != mlen.(u64) return io.OtherParse

    echo<io.Buf> = io.NewBuf(rn.(i32))
    std.memcpy(echo.ptr(), rbuf.data_ptr(), rn)
    wfut2<EchoWriteAll> = EchoWriteAll::new(server, echo)
    werr2<i32> = wfut2.await
    if werr2 != io.Ok return werr2

    rbuf2<aio.ReadBuf> = make_read_buf(16)
    rfut2<EchoRead> = EchoRead::new(client, rbuf2)
    rerr2<i32>, n2<u64> = rfut2.await
    if rerr2 != io.Ok return rerr2
    if n2 != mlen.(u64) return io.OtherParse

    src<u8*> = msg.str()
    got<u8*> = rbuf2.data_ptr()
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_tcp_echo(){
    fmt.println("int_tcp_echo test")
    fmt.println("build")
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_io()
    body<runtime.Future> = tcp_echo_body()
    if body == null {
        os.die("tcp_echo_body returned null future")
    }
    fut_bits<u64> = 0
    fut_bits = body
    rerr<i32>, result<i64> = rt.builder_block_on(b, fut_bits, 0)
    fmt.println("back")
    if rerr != 0 {
        fmt.println("block_on failed")
        os.exit(1)
    }
    ri<i32> = 0
    ri = result
    if ri != io.Ok {
        fmt.println("body failed")
        fmt.println(int(ri))
        os.exit(1)
    }
    fmt.println("int_tcp_echo passed")
}

fn main(){
    int_tcp_echo()
}
