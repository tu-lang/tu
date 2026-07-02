// Async TCP listener. Wraps a netio TcpListener registered with the current
// runtime's IO driver through PollEvented: bind + readable-driven accept.
//
// Design note (task 15.13): the spec models this as `class TcpListener`; per
// library-static-only it is a static `mem` holding an asyncio.io.PollEvented.

use net
use io
use runtime
use netio
use netio.net.tcp as nettcp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async TCP listener: netio source + IO-driver registration for read readiness.
mem TcpListener {
    aio.PollEvented* io
}

// Bind to `addr` and register with the current runtime's IO driver for read
// readiness. netio's bind already sets SO_REUSEADDR + listen(1024). Returns
// (io.Ok, listener) or an error with a null listener (RuntimeShutdown when
// there is no active IO driver).
const TcpListener::bind(addr<net.SocketAddr>) (i32, TcpListener) {
    err<i32>, inner<nettcp.TcpListener> = nettcp.TcpListener::bind(addr)
    if inner == null return err, null
    return TcpListener::from_netio(inner)
}

// Register an already-bound netio TcpListener with the IO driver for read
// readiness. Returns (io.Ok, listener) or an error with null.
const TcpListener::from_netio(inner<nettcp.TcpListener>) (i32, TcpListener) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver.(rt.DriverHandle)
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = aio.Interest::readable()
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new TcpListener { io: pe }
}

// Borrow the underlying netio TcpListener.
TcpListener::netio_listener() nettcp.TcpListener {
    return this.io.source()
}

// IoOp for a single accept4 syscall. The accepted netio stream + peer address
// are stashed in out_stream / out_addr; try_perform returns (err, 0) since the
// interesting outputs are the stashed fields.
mem AcceptOp {
    nettcp.TcpListener* listener
    nettcp.TcpStream*   out_stream
    net.SocketAddr*     out_addr
}

impl rtio.IoOp for AcceptOp {
    fn try_perform() i32, i64 {
        err<i32>, s<nettcp.TcpStream>, addr<net.SocketAddr> = this.listener.accept()
        this.out_stream = s
        this.out_addr   = addr
        return err, 0
    }
}

// Async leaf driving the accept IoOp through PollEvented::poll_read_io.
mem AcceptFut: async {
    aio.PollEvented* io
    AcceptOp*        op
}

AcceptFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    return runtime.PollReady, e
}

// Accept the next inbound connection. Awaits read readiness as needed, then
// registers the accepted stream with the IO driver. Returns (io.Ok, stream,
// peer_addr) or (err, null, null).
async TcpListener::accept() i32, TcpStream, net.SocketAddr {
    op<AcceptOp> = new AcceptOp {
        listener: this.io.source(),
        out_stream: null,
        out_addr: null
    }
    f<AcceptFut> = new AcceptFut { io: this.io, op: op }
    err<i32> = f.await
    if err != io.Ok return err, null, null
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(op.out_stream, op.out_addr)
    if rerr != io.Ok return rerr, null, null
    return io.Ok, s, op.out_addr
}

// Poll form of accept for hand-written state machines. Returns a Poll state as
// the first value: PollPending while no connection is ready, PollError on a
// syscall / registration failure, or PollReady with the registered stream and
// its peer address.
TcpListener::poll_accept(ctx<u64>) i32, TcpStream, net.SocketAddr {
    op<AcceptOp> = new AcceptOp {
        listener: this.io.source(),
        out_stream: null,
        out_addr: null
    }
    e<i32>, n<i64> = this.io.poll_read_io(ctx, op)
    if e == runtime.PollPending return runtime.PollPending, null, null
    if e != io.Ok return runtime.PollError, null, null
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(op.out_stream, op.out_addr)
    if rerr != io.Ok return runtime.PollError, null, null
    return runtime.PollReady, s, op.out_addr
}
