// Integration test (task 15.17): Unix-domain stream echo round-trip.
// Full api path: ioutil.write_all / ioutil.read via AsyncWrite / AsyncRead.

use fmt
use os
use io
use string
use std
use sys
use runtime
use asyncio.runtime as rt
use asyncio.net.unix as unix
use asyncio.io as aio
use asyncio.io.util as ioutil

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

async unix_echo_body() {
    path<string.String> = string.S(*"/tmp/asyncio_int_unix_echo.sock")
    sys.unlink(path.str())

    berr<i32>, listener<unix.UnixListener> = unix.unix_listener_bind(path)
    if berr != io.Ok return berr
    if listener == null return io.Other

    cerr<i32>, client<unix.UnixStream> = unix.UnixStream::connect(path).await
    if cerr != io.Ok return cerr

    aerr<i32>, server<unix.UnixStream> = listener.accept().await
    if aerr != io.Ok return aerr

    msg<string.String> = string.S(*"ping")
    mlen<i32> = std.strlen(msg.str())
    mlen_u<u64> = mlen.(u64)

    werr<i32> = ioutil.write_all(client, str_buf(msg)).await
    if werr != io.Ok return werr

    own1<io.Buf> = io.NewBuf(16)
    rb1<aio.ReadBuf> = ioutil.read_buf_over(own1)
    rerr<i32>, rn<u64> = ioutil.read(server, rb1).await
    if rerr != io.Ok return rerr
    if rn != mlen_u return io.OtherParse

    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    werr2<i32> = ioutil.write_all(server, echo).await
    if werr2 != io.Ok return werr2

    own2<io.Buf> = io.NewBuf(16)
    rb2<aio.ReadBuf> = ioutil.read_buf_over(own2)
    rerr2<i32>, n2<u64> = ioutil.read(client, rb2).await
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
    b = b.enable_io()
    rerr<i32>, result<i64> = rt.builder_block_on(b, unix_echo_body(), 0)
    if rerr != 0 {
        os.dief("block_on failed: %d", rerr)
    }
    ri<i32> = result
    if ri != io.Ok {
        os.dief("unix_echo body failed: %d", ri)
    }
    fmt.println("int_unix_echo passed")
}

fn main() {
    int_unix_echo()
}
