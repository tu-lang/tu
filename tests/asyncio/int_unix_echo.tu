// Integration test (task 15.17): Unix-domain stream echo round-trip over
// asyncio.net.unix. Binds a listener on a tmp socket path, connects a client,
// accepts the server side, then echoes a payload client -> server -> client.
//
// IO/async paths are Linux-only; this file is validated on Linux CI, not on
// the Windows dev host. Socket-file cleanup is left to the harness / tmpfs.

use fmt
use os
use io
use string
use asyncio.runtime as rt
use asyncio.net.unix as unix
use asyncio.io as aio
use asyncio.io.util as ioext

// Allocate a ReadBuf backed by a fresh `cap`-byte buffer.
fn make_read_buf(cap<i32>) aio.ReadBuf {
    b<io.Buf> = io.NewBuf(cap)
    buffer<io.Buffer> = io.Buffer::from_uinit(b)
    return aio.ReadBuf::new(buffer)
}

// Wrap a String's bytes as a borrowed io.Buf (no copy).
fn str_buf(s<string.String>) io.Buf {
    return new io.Buf { inner: s.str(), len: s.len().(u64) }
}

// Drive the full echo exchange on a single task. Returns io.Ok on success or
// the first error code encountered.
async unix_echo_body() i32 {
    path<string.String> = string.S(*"/tmp/asyncio_int_unix_echo.sock")

    berr<i32>, listener<unix.UnixListener> = unix.UnixListener::bind(path)
    if berr != io.Ok return berr

    cerr<i32>, client<unix.UnixStream> = unix.UnixStream::connect(path).await
    if cerr != io.Ok return cerr

    aerr2<i32>, server<unix.UnixStream>, _ = listener.accept().await
    if aerr2 != io.Ok return aerr2

    // client -> server
    msg<string.String> = string.S(*"ping")
    werr<i32> = ioext.write_all(client.(u64), str_buf(msg)).await
    if werr != io.Ok return werr

    // server reads
    rbuf<aio.ReadBuf> = make_read_buf(16)
    rerr<i32>, n<u64> = ioext.read(server.(u64), rbuf).await
    if rerr != io.Ok return rerr
    if n != msg.len().(u64) return io.OtherParse

    // server -> client (echo the bytes just read)
    echo<io.Buf> = new io.Buf { inner: rbuf.inner.buf.ptr(), len: n }
    werr2<i32> = ioext.write_all(server.(u64), echo).await
    if werr2 != io.Ok return werr2

    // client reads the echo back
    rbuf2<aio.ReadBuf> = make_read_buf(16)
    rerr2<i32>, n2<u64> = ioext.read(client.(u64), rbuf2).await
    if rerr2 != io.Ok return rerr2
    if n2 != msg.len().(u64) return io.OtherParse

    src<u8*> = msg.str()
    got<u8*> = rbuf2.inner.buf.ptr()
    i<u64> = 0
    while i < n2 {
        if got[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

fn int_unix_echo(){
    fmt.println("int_unix_echo test")

    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    berr<i32>, r<rt.Runtime> = b.build()
    if berr != 0 os.dief("runtime build failed: %d", berr)

    rerr<i32>, result<i64> = r.block_on(unix_echo_body())
    if rerr != 0 os.dief("block_on failed: %d", rerr)
    if result.(i32) != io.Ok os.dief("unix echo body failed: %d", result.(i32))

    r.shutdown_background()
    fmt.println("int_unix_echo passed")
}

fn main(){
    int_unix_echo()
}
