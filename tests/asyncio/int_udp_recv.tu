// Integration test (task 15.7): UDP echo round-trip over asyncio.net.udp.
// Binds a server + client on loopback, client send_to -> server recv_from ->
// server echoes back -> client recv_from, asserting the payload round-trips.
//
// IO/async paths are Linux-only; validated on Linux CI, not the Windows host.

use fmt
use os
use io
use string
use net
use asyncio.runtime as rt
use asyncio.net as anet

// Wrap a String's bytes as a borrowed io.Buf (no copy).
fn str_buf(s<string.String>) io.Buf {
    return new io.Buf { inner: s.str(), len: s.len().(u64) }
}

// Parse a loopback "ip:port" literal, aborting on failure.
fn addr_of(lit<string.String>) net.SocketAddr {
    err<i32>, a<net.SocketAddr> = anet.parse_socket_addr(lit.str(), lit.len())
    if err != io.Ok os.dief("parse addr failed: %d", err)
    return a
}

// Drive the full echo exchange. Returns io.Ok on success or first error code.
async udp_echo_body() i32 {
    saddr<net.SocketAddr> = addr_of(string.S(*"127.0.0.1:34568"))
    caddr<net.SocketAddr> = addr_of(string.S(*"127.0.0.1:34569"))

    serr<i32>, server<anet.UdpSocket> = anet.UdpSocket::bind(saddr)
    if serr != io.Ok return serr
    cerr<i32>, client<anet.UdpSocket> = anet.UdpSocket::bind(caddr)
    if cerr != io.Ok return cerr

    msg<string.String> = string.S(*"ping")

    // client -> server
    werr<i32>, _ = client.send_to(str_buf(msg), saddr).await
    if werr != io.Ok return werr

    // server receives, learns the client's address
    rbuf<io.Buf> = io.NewBuf(16)
    rerr<i32>, n<u64>, from<net.SocketAddr> = server.recv_from(rbuf).await
    if rerr != io.Ok return rerr
    if n != msg.len().(u64) return io.OtherParse

    // server echoes back to the origin
    echo<io.Buf> = new io.Buf { inner: rbuf.ptr(), len: n }
    werr2<i32>, _ = server.send_to(echo, from).await
    if werr2 != io.Ok return werr2

    // client receives the echo
    rbuf2<io.Buf> = io.NewBuf(16)
    rerr2<i32>, n2<u64>, _ = client.recv_from(rbuf2).await
    if rerr2 != io.Ok return rerr2
    if n2 != msg.len().(u64) return io.OtherParse

    src<u8*> = msg.str()
    got<u8*> = rbuf2.ptr()
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
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    rerr<i32>, result<i64> = r.block_on(udp_echo_body())
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("udp echo body failed: %d", result.(i32))

    r.shutdown_background()
    fmt.println("int_udp_echo passed")
}

fn main(){
    int_udp_echo()
}
