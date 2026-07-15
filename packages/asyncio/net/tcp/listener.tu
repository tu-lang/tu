// Async TCP listener. Wraps a netio TcpListener registered with the current
// runtime's IO driver through PollEvented: bind + readable-driven accept.
//
// Member async+await is unavailable for multi-return; AcceptFut::poll returns
// (PollReady, err, stream) so accept().await matches tokio accept semantics.

use net
use io
use runtime
use netio
use netio.net.tcp as nettcp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

mem TcpListener {
    aio.PollEvented* io
}

const TcpListener::bind(addr<net.SocketAddr>) (i32, TcpListener) {
    err<i32>, inner<nettcp.TcpListener> = nettcp.TcpListener::bind(addr)
    if inner == null return err, null
    return TcpListener::from_netio(inner)
}

const TcpListener::from_netio(inner<nettcp.TcpListener>) (i32, TcpListener) {
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    ok_code<i32> = 1           // io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, null
    dh<rt.DriverHandle> = rc.driver
    if dh == null || dh.io_handle == null return shut_err, null

    interest<netio.Interest> = netio.readable_interest()
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return ok_code, new TcpListener { io: pe }
}

TcpListener::netio_listener() nettcp.TcpListener {
    return this.io.source()
}

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

// Leaf future: poll_read_io accept + register accepted stream with IO driver.
mem AcceptFut: async {
    aio.PollEvented* io
    AcceptOp*        op
}

AcceptFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    if e != io.Ok return runtime.PollReady, e, null
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(this.op.out_stream, this.op.out_addr)
    if rerr != io.Ok return runtime.PollReady, rerr, null
    return runtime.PollReady, io.Ok, s
}

// Mother: async accept — async entry returns AcceptFut leaf (no await body).
async TcpListener::accept() {
    op<AcceptOp> = new AcceptOp {
        listener: this.io.source(),
        out_stream: null,
        out_addr: null
    }
    return new AcceptFut { io: this.io, op: op }
}

TcpListener::poll_accept(ctx<u64>) i32, TcpStream {
    op<AcceptOp> = new AcceptOp {
        listener: this.io.source(),
        out_stream: null,
        out_addr: null
    }
    e<i32>, n<i64> = this.io.poll_read_io(ctx, op)
    if e == runtime.PollPending return runtime.PollPending, null
    if e != io.Ok return runtime.PollError, null
    rerr<i32>, s<TcpStream> = TcpStream::from_netio(op.out_stream, op.out_addr)
    if rerr != io.Ok return runtime.PollError, null
    return runtime.PollReady, s
}
