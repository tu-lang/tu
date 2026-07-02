// Async TCP stream. Wraps a netio TcpStream registered with the current
// runtime's IO driver through PollEvented: connect + readiness + byte
// read/write with AsyncRead / AsyncWrite.
//
// Design note (task 15.9): the spec models this as `class TcpStream`; per
// library-static-only it is a static `mem` holding an asyncio.io.PollEvented.
//
// Deviation (local_addr): the underlying net/sys layer exposes no
// getsockname binding, so local_addr is unsupported (returns io.Unsupported).
// peer_addr is served from the address cached at connect/accept time.

use net
use io
use runtime
use netio
use netio.net.tcp as nettcp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async TCP stream: netio source + IO-driver registration via PollEvented.
// `peer` caches the remote address (connect target / accept peer) since the
// stack has no getpeername.
mem TcpStream {
    aio.PollEvented* io
    net.SocketAddr*  peer
}

// Register an already-connected netio TcpStream with the IO driver for
// read + write readiness. `peer` is the remote address to cache. Returns
// (io.Ok, stream) or an error with a null stream (RuntimeShutdown when there
// is no active IO driver).
const TcpStream::from_netio(inner<nettcp.TcpStream>, peer<net.SocketAddr>) (i32, TcpStream) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver.(rt.DriverHandle)
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = aio.interest_add(aio.Interest::readable(), aio.Interest::writable())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new TcpStream { io: pe, peer: peer }
}

// Borrow the underlying netio TcpStream (for issuing raw read/write syscalls).
TcpStream::netio_sock() nettcp.TcpStream {
    return this.io.source()
}

// Cached remote address. Returns (io.Ok, addr) or (io.Unsupported, null) when
// the stream was built without a known peer.
TcpStream::peer_addr() i32, net.SocketAddr {
    if this.peer == null return io.Unsupported, null
    return io.Ok, this.peer
}

// Local address is unsupported: the net/sys layer has no getsockname binding.
TcpStream::local_addr() i32, net.SocketAddr {
    return io.Unsupported, null
}

// ---- connect -------------------------------------------------------------

// Async leaf that completes when the in-flight connect resolves: it parks on
// write readiness, then reads SO_ERROR via take_error to distinguish success
// from a failed connect (e.g. ECONNREFUSED).
mem ConnectFut: async {
    aio.PollEvented* io
}

// Poll: wait for writable, then verify the socket error. Returns PollReady with
// io.Ok on success, the pending SO_ERROR code on a failed connect, or a driver
// error code; PollPending while the connect is still in flight.
ConnectFut::poll(ctx){
    c<u64> = ctx.(u64)
    werr<i32>, wev<rtio.ReadyEvent> = this.io.poll_write_ready(c)
    if werr == runtime.PollPending return runtime.PollPending
    if werr != 0 return runtime.PollReady, werr
    // Writable: confirm the connect actually succeeded.
    sock<nettcp.TcpStream> = this.io.source()
    ok<i32>, has<i32>, soerr<i32> = sock.take_error()
    if ok != io.Ok return runtime.PollReady, ok
    if has == net.Has return runtime.PollReady, soerr
    return runtime.PollReady, io.Ok
}

// Connect to `addr`. netio issues a nonblocking connect (EINPROGRESS -> Ok);
// this awaits write readiness and the SO_ERROR check before returning the
// registered stream. Returns (io.Ok, stream) or (err, null).
async TcpStream::connect(addr<net.SocketAddr>) i32, TcpStream {
    cerr<i32>, inner<nettcp.TcpStream> = nettcp.TcpStream::connect(addr)
    if inner == null return cerr, null
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(inner, addr)
    if rerr != io.Ok return rerr, null
    f<ConnectFut> = new ConnectFut { io: s.io }
    werr<i32> = f.await
    if werr != io.Ok return werr, null
    return io.Ok, s
}

// ---- readiness -----------------------------------------------------------

// Async leaf: park until any bit in the requested interest becomes ready. The
// ready bits are stashed in `result`; poll returns io.Ok once non-empty.
mem TcpReadyFut: async {
    aio.PollEvented* io          // borrowed registration
    i32              want_read   // 1 when the caller asked for read readiness
    i32              want_write  // 1 when the caller asked for write readiness
    aio.Ready*       result      // filled with the ready bits on completion
}

// Poll read/write readiness per the requested interest, OR-ing whatever the
// driver reports. Returns PollReady once any bit is set (result filled), a
// driver error code verbatim, or PollPending while nothing is ready yet.
TcpReadyFut::poll(ctx){
    c<u64> = ctx.(u64)
    bits<i32> = 0
    if this.want_read == 1 {
        rerr<i32>, rev<rtio.ReadyEvent> = this.io.poll_read_ready(c)
        if rerr == 0 {
            bits = bits | rev.ready.bits
        } else if rerr != runtime.PollPending {
            return runtime.PollReady, rerr
        }
    }
    if this.want_write == 1 {
        werr<i32>, wev<rtio.ReadyEvent> = this.io.poll_write_ready(c)
        if werr == 0 {
            bits = bits | wev.ready.bits
        } else if werr != runtime.PollPending {
            return runtime.PollReady, werr
        }
    }
    if bits != 0 {
        this.result = aio.Ready::from_bits(bits)
        return runtime.PollReady, io.Ok
    }
    return runtime.PollPending
}

// Await read and/or write readiness for `interest`. Returns (io.Ok, ready)
// with the ready bits, or (err, null) on driver error.
async TcpStream::ready(interest<netio.Interest>) i32, aio.Ready {
    f<TcpReadyFut> = new TcpReadyFut {
        io: this.io,
        want_read: 0,
        want_write: 0,
        result: null
    }
    if interest.is_readable() f.want_read = 1
    if interest.is_writable() f.want_write = 1
    err<i32> = f.await
    return err, f.result
}

// Await readable readiness. Returns io.Ok or a driver error code.
async TcpStream::readable() i32 {
    f<TcpReadyFut> = new TcpReadyFut { io: this.io, want_read: 1, want_write: 0, result: null }
    return f.await
}

// Await writable readiness. Returns io.Ok or a driver error code.
async TcpStream::writable() i32 {
    f<TcpReadyFut> = new TcpReadyFut { io: this.io, want_read: 0, want_write: 1, result: null }
    return f.await
}

// ---- read / write --------------------------------------------------------

// IoOp for a single read syscall into `buf`. Returns (err, bytes); err ==
// io.WouldBlock makes PollEvented retry after the next readable readiness.
mem TcpReadOp {
    nettcp.TcpStream* sock
    io.Buf*           buf
}

impl rtio.IoOp for TcpReadOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.read(this.buf)
        return err, n.(i64)
    }
}

// IoOp for a single write syscall from `buf`.
mem TcpWriteOp {
    nettcp.TcpStream* sock
    io.Buf*           buf
}

impl rtio.IoOp for TcpWriteOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.write(this.buf)
        return err, n.(i64)
    }
}

// Non-blocking read into `buf`: one readable-readiness check + one syscall.
// Returns (io.Ok, bytes), (io.WouldBlock, 0) when not ready, or (err, 0).
TcpStream::try_read(buf<io.Buf>) i32, u64 {
    sock<nettcp.TcpStream> = this.io.source()
    op<TcpReadOp> = new TcpReadOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.io.try_io(aio.Interest::readable(), op)
    return err, val.(u64)
}

// Non-blocking write from `buf`: one writable-readiness check + one syscall.
// Returns (io.Ok, bytes), (io.WouldBlock, 0) when not ready, or (err, 0).
TcpStream::try_write(buf<io.Buf>) i32, u64 {
    sock<nettcp.TcpStream> = this.io.source()
    op<TcpWriteOp> = new TcpWriteOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.io.try_io(aio.Interest::writable(), op)
    return err, val.(u64)
}

// Shut down the read/write half(s) per `how` (net.ShutdownRead/Write/Both).
TcpStream::shutdown(how<i32>) i32 {
    sock<nettcp.TcpStream> = this.io.source()
    return sock.shutdown(how)
}

// AsyncRead: read into the unfilled tail of `buf`, driving the read IoOp
// through PollEvented (retries on WouldBlock). Returns PollPending, PollReady
// (buf.filled advanced by whatever landed), or PollError on syscall failure.
impl aio.AsyncRead for TcpStream {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        base<io.Buf>    = buf.inner.buf
        _, tail<io.Buf> = base.split_at(buf.filled)
        op<TcpReadOp>   = new TcpReadOp { sock: this.io.source(), buf: tail }
        e<i32>, n<i64>  = this.io.poll_read_io(ctx, op)
        if e == runtime.PollPending return runtime.PollPending
        if e == io.Ok {
            if n > 0 buf.advance(n.(u64))
            return runtime.PollReady
        }
        return runtime.PollError
    }
}

// AsyncWrite: write from `buf`, driving the write IoOp through PollEvented.
// poll_flush is a no-op (no user-space buffering); poll_shutdown closes the
// write half.
impl aio.AsyncWrite for TcpStream {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        op<TcpWriteOp> = new TcpWriteOp { sock: this.io.source(), buf: buf }
        e<i32>, n<i64> = this.io.poll_write_io(ctx, op)
        if e == runtime.PollPending return runtime.PollPending, 0
        if e == io.Ok return runtime.PollReady, n.(u64)
        return runtime.PollError, 0
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        sock<nettcp.TcpStream> = this.io.source()
        sock.shutdown(net.ShutdownWrite)
        return runtime.PollReady
    }
}
