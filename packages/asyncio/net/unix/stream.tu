// Async Unix-domain stream socket. Wraps a netio UnixStream registered with
// the current runtime's IO driver through PollEvented: connect + readiness +
// byte read/write with AsyncRead / AsyncWrite. Mirrors net.tcp.TcpStream with
// a path-based connect and no peer SocketAddr.

use string
use net
use io
use runtime
use netio
use netio.net.uds as netuds
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async unix stream: netio source + IO-driver registration via PollEvented.
mem UnixStream {
    aio.PollEvented* io
}

// Register an already-connected netio UnixStream with the IO driver for read +
// write readiness. Returns (io.Ok, stream) or an error with null
// (RuntimeShutdown when there is no active IO driver).
const UnixStream::from_netio(inner<netuds.UnixStream>) (i32, UnixStream) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver.(rt.DriverHandle)
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = aio.interest_add(aio.Interest::readable(), aio.Interest::writable())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new UnixStream { io: pe }
}

// Borrow the underlying netio UnixStream.
UnixStream::netio_sock() netuds.UnixStream {
    return this.io.source()
}

// ---- connect -------------------------------------------------------------

// Async leaf that completes when the in-flight connect resolves: parks on
// write readiness, then reads SO_ERROR via take_error.
mem ConnectFut: async {
    aio.PollEvented* io
}

ConnectFut::poll(ctx){
    c<u64> = ctx.(u64)
    werr<i32>, wev<rtio.ReadyEvent> = this.io.poll_write_ready(c)
    if werr == runtime.PollPending return runtime.PollPending
    if werr != 0 return runtime.PollReady, werr
    sock<netuds.UnixStream> = this.io.source()
    ok<i32>, has<i32>, soerr<i32> = sock.take_error()
    if ok != io.Ok return runtime.PollReady, ok
    if has == net.Has return runtime.PollReady, soerr
    return runtime.PollReady, io.Ok
}

// Connect to the unix socket at `path`. netio issues a nonblocking connect
// (WouldBlock -> Ok); this awaits write readiness + SO_ERROR before returning
// the registered stream. Returns (io.Ok, stream) or (err, null).
async UnixStream::connect(path<string.String>) i32, UnixStream {
    cerr<i32>, inner<netuds.UnixStream> = netuds.UnixStream::connect(path)
    if inner == null return cerr, null
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(inner)
    if rerr != io.Ok return rerr, null
    f<ConnectFut> = new ConnectFut { io: s.io }
    werr<i32> = f.await
    if werr != io.Ok return werr, null
    return io.Ok, s
}

// Create an unnamed, connected socket pair. Both ends are registered with the
// IO driver. Returns (io.Ok, a, b) or (err, null, null).
const UnixStream::pair() (i32, UnixStream, UnixStream) {
    err<i32>, l<netuds.UnixStream>, r<netuds.UnixStream> = netuds.UnixStream::pair()
    if l == null return err, null, null
    lerr<i32>, ls<UnixStream> = UnixStream::from_netio(l)
    if lerr != io.Ok return lerr, null, null
    rerr<i32>, rs<UnixStream> = UnixStream::from_netio(r)
    if rerr != io.Ok return rerr, null, null
    return io.Ok, ls, rs
}

// ---- readiness -----------------------------------------------------------

// Async leaf: park until any bit in the requested interest becomes ready.
mem UnixReadyFut: async {
    aio.PollEvented* io
    i32              want_read
    i32              want_write
    aio.Ready*       result
}

UnixReadyFut::poll(ctx){
    st<i32>, err<i32>, r<aio.Ready> = aio.poll_ready_bits(this.io, this.want_read, this.want_write, ctx.(u64))
    if st == runtime.PollPending return runtime.PollPending
    if err != io.Ok return runtime.PollReady, err
    this.result = r
    return runtime.PollReady, io.Ok
}

// Await read and/or write readiness for `interest`.
async UnixStream::ready(interest<netio.Interest>) i32, aio.Ready {
    f<UnixReadyFut> = new UnixReadyFut { io: this.io, want_read: 0, want_write: 0, result: null }
    if interest.is_readable() f.want_read = 1
    if interest.is_writable() f.want_write = 1
    err<i32> = f.await
    return err, f.result
}

// Await readable readiness.
async UnixStream::readable() i32 {
    f<UnixReadyFut> = new UnixReadyFut { io: this.io, want_read: 1, want_write: 0, result: null }
    return f.await
}

// Await writable readiness.
async UnixStream::writable() i32 {
    f<UnixReadyFut> = new UnixReadyFut { io: this.io, want_read: 0, want_write: 1, result: null }
    return f.await
}

// ---- read / write --------------------------------------------------------

// IoOp for a single read syscall into `buf`.
mem UnixReadOp {
    netuds.UnixStream* sock
    io.Buf*            buf
}

impl rtio.IoOp for UnixReadOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.read(this.buf)
        return err, n.(i64)
    }
}

// IoOp for a single write syscall from `buf`.
mem UnixWriteOp {
    netuds.UnixStream* sock
    io.Buf*            buf
}

impl rtio.IoOp for UnixWriteOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.write(this.buf)
        return err, n.(i64)
    }
}

// Non-blocking read into `buf`.
UnixStream::try_read(buf<io.Buf>) i32, u64 {
    sock<netuds.UnixStream> = this.io.source()
    op<UnixReadOp> = new UnixReadOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.io.try_io(aio.Interest::readable(), op)
    return err, val.(u64)
}

// Non-blocking write from `buf`.
UnixStream::try_write(buf<io.Buf>) i32, u64 {
    sock<netuds.UnixStream> = this.io.source()
    op<UnixWriteOp> = new UnixWriteOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.io.try_io(aio.Interest::writable(), op)
    return err, val.(u64)
}

// Shut down the read/write half(s) per `how` (net.ShutdownRead/Write/Both).
UnixStream::shutdown(how<i32>) i32 {
    sock<netuds.UnixStream> = this.io.source()
    return sock.shutdown(how)
}

// AsyncRead: read into the unfilled tail of `buf` via the read IoOp.
impl aio.AsyncRead for UnixStream {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        base<io.Buf>    = buf.inner.buf
        _, tail<io.Buf> = base.split_at(buf.filled)
        op<UnixReadOp>  = new UnixReadOp { sock: this.io.source(), buf: tail }
        e<i32>, n<i64>  = this.io.poll_read_io(ctx, op)
        if e == runtime.PollPending return runtime.PollPending
        if e == io.Ok {
            if n > 0 buf.advance(n.(u64))
            return runtime.PollReady
        }
        return runtime.PollError
    }
}

// AsyncWrite: write from `buf` via the write IoOp; flush is a no-op,
// shutdown closes the write half.
impl aio.AsyncWrite for UnixStream {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        op<UnixWriteOp> = new UnixWriteOp { sock: this.io.source(), buf: buf }
        e<i32>, n<i64> = this.io.poll_write_io(ctx, op)
        if e == runtime.PollPending return runtime.PollPending, 0
        if e == io.Ok return runtime.PollReady, n.(u64)
        return runtime.PollError, 0
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        sock<netuds.UnixStream> = this.io.source()
        sock.shutdown(net.ShutdownWrite)
        return runtime.PollReady
    }
}
