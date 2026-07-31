// Integration test (task 15.7): UDP echo round-trip over asyncio.net.udp.
// Binds a server + client on loopback, client send_to -> server recv_from ->
// server echoes back -> client recv_from, asserting the payload round-trips.
//
// IO/async paths are Linux-only; validated on Linux CI, not the Windows host.

use fmt
use os
use io
use string
use std
use net
use asyncio.runtime as rt
use asyncio.net as anet
use asyncio.net.udp as audp
use asyncio.util

// Owned copy of String bytes as io.Buf (avoid new io.Buf { inner/len } traps).
fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

// Parse a loopback "ip:port" literal, aborting on failure.
fn addr_of(lit<string.String>) net.SocketAddr {
    slen<i32> = std.strlen(lit.str())
    err<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(lit.str(), slen)
    if err != io.Ok os.dief("parse addr failed: %d", err)
    return addr
}

// Drive the full echo exchange. Returns io.Ok on success or first error code.
async udp_echo_body() {
    saddr<net.SocketAddr> = addr_of(string.S(*"127.0.0.1:34568"))
    caddr<net.SocketAddr> = addr_of(string.S(*"127.0.0.1:34569"))

    serr<i32>, server<audp.UdpSocket> = audp.udp_bind(saddr)
    if serr != io.Ok return serr
    if server == null return io.Other

    cerr<i32>, client<audp.UdpSocket> = audp.udp_bind(caddr)
    if cerr != io.Ok return cerr
    if client == null return io.Other

    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())
    mlen_u<u64> = mlen.(u64)

    // client -> server
    werr<i32>, _ = client.send_to(str_buf(msg), saddr).await
    if werr != io.Ok return werr

    // server receives, learns the client's address (typed peer SocketAddr)
    rbuf<io.Buf> = io.NewBuf(16)
    rerr<i32>, n_i<i64>, from<net.SocketAddr> = server.recv_from(rbuf).await
    if rerr != io.Ok return rerr
    n<u64> = n_i.(u64)
    if n != mlen_u return io.OtherParse
    if from == null return io.OtherParse

    // server echoes back to the origin
    echo<io.Buf> = io.NewBuf(n.(i32))
    ep<i8*> = echo.ptr()
    rp<i8*> = rbuf.ptr()
    std.memcpy(ep, rp, n)
    werr2<i32>, _ = server.send_to(echo, from).await
    if werr2 != io.Ok return werr2

    // client receives the echo
    rbuf2<io.Buf> = io.NewBuf(16)
    rerr2<i32>, n2_i<i64>, peer2<net.SocketAddr> = client.recv_from(rbuf2).await
    if rerr2 != io.Ok return rerr2
    if peer2 == null return io.OtherParse
    n2<u64> = n2_i.(u64)
    if n2 != mlen_u return io.OtherParse

    src<u8*> = msg.str()
    got_p<i8*> = rbuf2.ptr()
    got<u8*> = null
    got = got_p
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_udp_echo(){
    fmt.println("int_udp_echo test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    rerr<i32>, result<i64> = rt.builder_block_on(b, udp_echo_body(), 0)
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    ri<i32> = 0
    ri = result
    if ri != io.Ok os.dief("udp echo body failed: %d", ri)

    fmt.println("int_udp_echo passed")
}

fn main(){
    int_udp_echo()
}
