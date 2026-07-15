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
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    ok_code<i32> = 1           // io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, null
    dh<rt.DriverHandle> = rc.driver
    if dh == null || dh.io_handle == null return shut_err, null

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return ok_code, new TcpStream { io: pe, peer: peer }
}

// Borrow the underlying netio TcpStream (for issuing raw read/write syscalls).
TcpStream::netio_sock() nettcp.TcpStream {
    return this.io.source()
}

// Cached remote address. Returns (io.Ok, addr) or (io.Unsupported, null) when
// the stream was built without a known peer.
TcpStream::peer_addr() {
    if this.peer == null return io.Unsupported, null
    return io.Ok, this.peer
}

// Local address is unsupported: the net/sys layer has no getsockname binding.
TcpStream::local_addr() {
    return io.Unsupported, null
}

// ---- connect -------------------------------------------------------------

// Async leaf: connect + register + write readiness + SO_ERROR.
// poll returns (PollReady, err, stream) so connect().await matches tokio.
mem ConnectFut: async {
    aio.PollEvented* io
    TcpStream*       stream
    i32              stage
}

ConnectFut::poll(ctx){
    // Numeric codes: leaf-poll asmgen sometimes fails to resolve io.*/aerr.* consts.
    other_err<i32> = 16908328       // io.Other
    shut_err<i32> = 0x03020005      // aerr.RuntimeShutdown
    ok_code<i32> = 1                // io.Ok
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    if this.stage == -1 return ready, other_err, null
    if this.stage == -2 return ready, shut_err, null
    if this.io == null return ready, other_err, null
    c<u64> = ctx.(u64)
    werr<i32>, wev<rtio.ReadyEvent> = this.io.poll_write_ready(c)
    if werr == pend return pend
    if werr != 0 return ready, werr, null
    sock<nettcp.TcpStream> = this.io.source()
    ok<i32>, has<i32>, soerr<i32> = sock.take_error()
    if ok != ok_code return ready, ok, null
    if has == net.Has return ready, soerr, null
    return ready, ok_code, this.stream
}

// Mother: TcpStream::connect — async entry returns ConnectFut leaf (no await body).
async TcpStream::connect(addr<net.SocketAddr>) {
    cerr<i32>, inner<nettcp.TcpStream> = nettcp.TcpStream::connect(addr)
    if inner == null {
        return new ConnectFut { io: null, stream: null, stage: -1 }
    }
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(inner, addr)
    if rerr != io.Ok {
        return new ConnectFut { io: null, stream: null, stage: -2 }
    }
    return new ConnectFut { io: s.io, stream: s, stage: 0 }
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
    st<i32>, err<i32>, r<aio.Ready> = aio.poll_ready_bits(this.io, this.want_read, this.want_write, ctx.(u64))
    if st == runtime.PollPending return runtime.PollPending
    if err != io.Ok return runtime.PollReady, err
    this.result = r
    return runtime.PollReady, io.Ok
}

// Mother: ready / readable / writable — return leaf futurs (no member await).
TcpStream::ready(interest<netio.Interest>) TcpReadyFut {
    f<TcpReadyFut> = new TcpReadyFut {
        io: this.io,
        want_read: 0,
        want_write: 0,
        result: null
    }
    if netio.interest_is_readable(interest) == 1 f.want_read = 1
    if netio.interest_is_writable(interest) == 1 f.want_write = 1
    return f
}

TcpStream::readable() TcpReadyFut {
    return new TcpReadyFut { io: this.io, want_read: 1, want_write: 0, result: null }
}

TcpStream::writable() TcpReadyFut {
    return new TcpReadyFut { io: this.io, want_read: 0, want_write: 1, result: null }
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
    err<i32>, val<i64> = this.io.try_io(netio.readable_interest(), op)
    return err, val.(u64)
}

// Non-blocking write from `buf`: one writable-readiness check + one syscall.
// Returns (io.Ok, bytes), (io.WouldBlock, 0) when not ready, or (err, 0).
TcpStream::try_write(buf<io.Buf>) i32, u64 {
    sock<nettcp.TcpStream> = this.io.source()
    op<TcpWriteOp> = new TcpWriteOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.io.try_io(netio.writable_interest(), op)
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
// Mother: TcpStream::poll_read_priv -> PollEvented::poll_read.
impl aio.AsyncRead for TcpStream {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        rem<u64> = buf.remaining()
        if rem == 0 return runtime.PollReady
        // Build a temporary io.Buf over the unfilled region (not owned).
        tail<io.Buf> = new io.Buf {
            data_ptr: buf.unfilled_ptr(),
            byte_len: rem
        }
        op<TcpReadOp> = new TcpReadOp { sock: this.io.source(), buf: tail }
        e<i32>, n<i64> = this.io.poll_read_io(ctx, op)
        if e == runtime.PollPending return runtime.PollPending
        if e == io.Ok {
            if n > 0 buf.advance(n.(u64))
            return runtime.PollReady
        }
        return runtime.PollError
    }
}

// AsyncWrite: write from `buf_bits` (io.Buf as u64), driving PollEvented.
// Mother: poll_write_priv; poll_flush is a no-op; poll_shutdown closes write half.
impl aio.AsyncWrite for TcpStream {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        b<io.Buf> = io.buf_from_bits(buf_bits)
        op<TcpWriteOp> = new TcpWriteOp { sock: this.io.source(), buf: b }
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
