// Integration test (task 15.16): TCP echo round-trip over asyncio.net.tcp.
// Binds a loopback listener, connects a client, accepts the server side, then
// client -> server -> client echoes a payload and asserts it round-trips.
//
// IO/async paths are Linux-only; this file is validated on Linux CI, not on
// the Windows dev host.

use fmt
use os
use io
use string
use net
use asyncio.runtime as rt
use asyncio.net as anet
use asyncio.net.tcp as tcp
use asyncio.io as aio
use asyncio.io.util as ioext

LOOPBACK<string> = "127.0.0.1:34567"

// Allocate a ReadBuf backed by a fresh `cap`-byte buffer.
fn make_read_buf(cap<i32>) aio.ReadBuf {
    b<io.Buf> = io.NewBuf(cap)
    buffer<io.Buffer> = io.Buffer::from_uinit(b)
    return aio.ReadBuf::new(buffer)
}

// Wrap a String's bytes as a borrowed io.Buf (no copy).
fn str_buf(s<string.String>) io.Buf {
    slen<u64> = s.len()
    return new io.Buf { inner: s.str(), len: slen }
}

// Drive the full echo exchange on a single task. Returns io.Ok on success or
// the first error code encountered.
async tcp_echo_body() {
    addr_s<string.String> = string.S(*"127.0.0.1:34567")
    perr<i32>, addr<net.SocketAddr> = anet.parse_socket_addr(addr_s.str(), int(addr_s.len()))
    if perr != io.Ok return perr

    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok return berr

    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok return cerr

    aerr2<i32>, server<tcp.TcpStream> = listener.accept().await
    if aerr2 != io.Ok return aerr2

    // client -> server
    msg<string.String> = string.S(*"ping")
    werr<i32> = ioext.write_all(client.(u64), str_buf(msg)).await
    if werr != io.Ok return werr

    // server reads
    rbuf<aio.ReadBuf> = make_read_buf(16)
    rerr<i32>, n<u64> = ioext.read(server.(u64), rbuf).await
    if rerr != io.Ok return rerr
    mlen<u64> = msg.len()
    if n != mlen return io.OtherParse

    // server -> client (echo the bytes just read)
    echo<io.Buf> = new io.Buf { inner: rbuf.inner.buf.inner, len: n }
    werr2<i32> = ioext.write_all(server.(u64), echo).await
    if werr2 != io.Ok return werr2

    // client reads the echo back
    rbuf2<aio.ReadBuf> = make_read_buf(16)
    rerr2<i32>, n2<u64> = ioext.read(client.(u64), rbuf2).await
    if rerr2 != io.Ok return rerr2
    if n2 != mlen return io.OtherParse

    // byte-compare the echoed payload with the original
    src<u8*> = msg.str()
    got<u8*> = rbuf2.inner.buf.inner
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_tcp_echo(){
    fmt.println("int_tcp_echo test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    rerr<i32>, result<i64> = r.block_on(tcp_echo_body())
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("tcp echo body failed: %d", result.(i32))

    r.shutdown_background()
    fmt.println("int_tcp_echo passed")
}

fn main(){
    int_tcp_echo()
}
