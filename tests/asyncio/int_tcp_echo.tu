// Integration test (task 15.16): TCP echo round-trip over asyncio.net.tcp.
// Full api path: ioutil.write_all / ioutil.read via aio.AsyncWrite / AsyncRead.

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
use asyncio.io as aio
use asyncio.io.util as ioutil
use asyncio.util

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

async tcp_echo_body() {
    addr_s<string.String> = string.S(*"127.0.0.1:34567")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok return perr

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

    // Multi-api concrete must bind AsyncWrite view before write_all
    // (InitApiVptr on assign; TcpStream also implements AsyncRead).
    wclient<aio.AsyncWrite> = client
    werr<i32> = ioutil.write_all(wclient, wbuf).await
    if werr != io.Ok return werr

    own1<io.Buf> = io.NewBuf(16)
    rb1<aio.ReadBuf> = aio.read_buf_from_i8(own1.ptr(), 16)
    rerr<i32>, rn<u64> = ioutil.read(server, rb1).await
    if rerr != io.Ok return rerr
    if rn != mlen_u return io.OtherParse
    cmp_err<i32> = cmp_buf_eq(own1, msg, rn)
    if cmp_err != io.Ok return cmp_err

    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    wserver<aio.AsyncWrite> = server
    werr2<i32> = ioutil.write_all(wserver, echo).await
    if werr2 != io.Ok return werr2

    own2<io.Buf> = io.NewBuf(16)
    rb2<aio.ReadBuf> = aio.read_buf_from_i8(own2.ptr(), 16)
    rerr2<i32>, n2<u64> = ioutil.read(client, rb2).await
    if rerr2 != io.Ok return rerr2
    if n2 != mlen_u return io.OtherParse
    cmp_err2<i32> = cmp_buf_eq(own2, msg, n2)
    if cmp_err2 != io.Ok return cmp_err2

    hold_err<i32> = atime.sleep(atime.from_millis(50)).await
    if hold_err != io.Ok return hold_err

    return io.Ok
}

// Same echo on a distinct port for multi_thread (avoid TIME_WAIT after CT).
async tcp_echo_body_mt() {
    addr_s<string.String> = string.S(*"127.0.0.1:34568")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok return perr

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

    wclient<aio.AsyncWrite> = client
    werr<i32> = ioutil.write_all(wclient, wbuf).await
    if werr != io.Ok return werr

    own1<io.Buf> = io.NewBuf(16)
    rb1<aio.ReadBuf> = aio.read_buf_from_i8(own1.ptr(), 16)
    rerr<i32>, rn<u64> = ioutil.read(server, rb1).await
    if rerr != io.Ok return rerr
    if rn != mlen_u return io.OtherParse
    cmp_err<i32> = cmp_buf_eq(own1, msg, rn)
    if cmp_err != io.Ok return cmp_err

    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    wserver<aio.AsyncWrite> = server
    werr2<i32> = ioutil.write_all(wserver, echo).await
    if werr2 != io.Ok return werr2

    own2<io.Buf> = io.NewBuf(16)
    rb2<aio.ReadBuf> = aio.read_buf_from_i8(own2.ptr(), 16)
    rerr2<i32>, n2<u64> = ioutil.read(client, rb2).await
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

// Same echo body under multi_thread + enable_all (IO + time park on workers).
fn int_tcp_echo_mt() {
    fmt.println("int_tcp_echo_mt test")
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    body<runtime.Future> = tcp_echo_body_mt()
    if body == null {
        os.die("tcp_echo_body_mt returned null future")
    }
    rerr<i32>, result<i64> = rt.builder_block_on(b, body, 0)
    if rerr != 0 {
        os.dief("mt block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("mt tcp_echo body failed: %d", ri)
    }
    fmt.println("int_tcp_echo_mt passed")
}

fn main() {
    int_tcp_echo()
    int_tcp_echo_mt()
}
