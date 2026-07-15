// Async Unix-domain listener. Wraps a netio UnixListener registered with the
// current runtime's IO driver through PollEvented: bind(path) + readable-driven
// accept. Mirrors net.tcp.TcpListener.

use string
use io
use runtime
use netio
use netio.net.uds as netuds
use netio.sys.uds as udsaddr
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async unix listener: netio source + IO-driver registration for read readiness.
mem UnixListener {
    aio.PollEvented* io
}

// Bind to the socket path and register for read readiness. Returns
// (io.Ok, listener) or an error with a null listener.
const UnixListener::bind(path<string.String>) (i32, UnixListener) {
    err<i32>, inner<netuds.UnixListener> = netuds.UnixListener::bind(path)
    if inner == null return err, null
    return UnixListener::from_netio(inner)
}

// Register an already-bound netio UnixListener with the IO driver.
const UnixListener::from_netio(inner<netuds.UnixListener>) (i32, UnixListener) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = netio.readable_interest()
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new UnixListener { io: pe }
}

// Borrow the underlying netio UnixListener.
UnixListener::netio_listener() netuds.UnixListener {
    return this.io.source()
}

// IoOp for a single accept syscall. The accepted netio stream + peer address
// are stashed in out_stream / out_addr.
mem UnixAcceptOp {
    netuds.UnixListener* listener
    netuds.UnixStream*   out_stream
    udsaddr.SocketAddr*  out_addr
}

impl rtio.IoOp for UnixAcceptOp {
    fn try_perform() i32, i64 {
        err<i32>, s<netuds.UnixStream>, addr<udsaddr.SocketAddr> = this.listener.accept()
        this.out_stream = s
        this.out_addr   = addr
        return err, 0
    }
}

// Async leaf driving the accept IoOp through PollEvented::poll_read_io.
mem UnixAcceptFut: async {
    aio.PollEvented* io
    UnixAcceptOp*    op
}

UnixAcceptFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    return runtime.PollReady, e
}

// Accept the next inbound connection. Awaits read readiness as needed, then
// registers the accepted stream. Returns (io.Ok, stream, peer_addr) or
// (err, null, null).
async UnixListener::accept() i32, UnixStream, udsaddr.SocketAddr {
    op<UnixAcceptOp> = new UnixAcceptOp { listener: this.io.source(), out_stream: null, out_addr: null }
    f<UnixAcceptFut> = new UnixAcceptFut { io: this.io, op: op }
    err<i32> = f.await
    if err != io.Ok return err, null, null
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(op.out_stream)
    if rerr != io.Ok return rerr, null, null
    return io.Ok, s, op.out_addr
}

// Poll form of accept. First value is a Poll state (PollPending / PollError /
// PollReady); on PollReady the stream + peer address follow.
UnixListener::poll_accept(ctx<u64>) i32, UnixStream, udsaddr.SocketAddr {
    op<UnixAcceptOp> = new UnixAcceptOp { listener: this.io.source(), out_stream: null, out_addr: null }
    e<i32>, n<i64> = this.io.poll_read_io(ctx, op)
    if e == runtime.PollPending return runtime.PollPending, null, null
    if e != io.Ok return runtime.PollError, null, null
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(op.out_stream)
    if rerr != io.Ok return runtime.PollError, null, null
    return runtime.PollReady, s, op.out_addr
}
