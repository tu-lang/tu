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
    shut_err<i32> = 0x03020005
    ok_code<i32> = 1
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, null
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null return shut_err, null
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 return shut_err, null
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    interest<netio.Interest> = netio.readable_interest()
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, null
    return ok_code, new UnixListener { io: pe }
}

// Borrow the underlying netio UnixListener.
UnixListener::raw_listener() netuds.UnixListener {
    bits<u64> = this.io.source()
    s<netuds.UnixListener> = null
    s = bits
    return s
}

// IoOp for a single accept syscall. Accepted stream + peer bits stashed on op.
mem UnixAcceptOp {
    netuds.UnixListener* listener
    netuds.UnixStream*   out_stream
    u64                  peer_bits
}

impl rtio.IoOp for UnixAcceptOp {
    fn try_perform() i32, i64 {
        err<i32>, s<netuds.UnixStream>, addr<udsaddr.SocketAddr> = this.listener.accept()
        this.out_stream = s
        this.peer_bits = addr.(u64)
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
async UnixListener::accept() {
    op<UnixAcceptOp> = new UnixAcceptOp { listener: this.raw_listener(), out_stream: null, peer_bits: 0 }
    f<UnixAcceptFut> = new UnixAcceptFut { io: this.io, op: op }
    err<i32> = f.await
    if err != io.Ok return err, null, 0
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(op.out_stream)
    if rerr != io.Ok return rerr, null, 0
    return io.Ok, s, op.peer_bits
}

// Poll form of accept. First value is a Poll state (PollPending / PollError /
// PollReady); on PollReady the stream + peer address follow.
UnixListener::poll_accept(ctx<u64>) i32, UnixStream, u64 {
    op<UnixAcceptOp> = new UnixAcceptOp { listener: this.raw_listener(), out_stream: null, peer_bits: 0 }
    e<i32>, n<i64> = this.io.poll_read_io(ctx, op)
    if e == runtime.PollPending return runtime.PollPending, null, 0
    if e != io.Ok return runtime.PollError, null, 0
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(op.out_stream)
    if rerr != io.Ok return runtime.PollError, null, 0
    return runtime.PollReady, s, op.peer_bits
}
