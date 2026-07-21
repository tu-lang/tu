// Async TCP listener. Wraps a netio TcpListener registered with the current
// runtime's IO driver through PollEvented: bind + readable-driven accept.
//
// Member async+await is unavailable for multi-return; AcceptFut::poll returns
// (PollReady, err, stream) so accept().await matches tokio accept semantics.

use net
use io
use fmt
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
    err<i32> = nettcp.TcpListener::bind(addr)
    if err != io.Ok return err, null
    inner<nettcp.TcpListener> = nettcp.tcp_listener_last()
    if inner == null return err, null
    return TcpListener::from_netio(inner)
}

const TcpListener::from_netio(inner<nettcp.TcpListener>) (i32, TcpListener) {
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    ok_code<i32> = 1           // io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null {
        return shut_err, null
    }
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null {
        return shut_err, null
    }
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 {
        return shut_err, null
    }
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    interest<netio.Interest> = netio.readable_interest()
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 {
        return perr, null
    }
    return ok_code, new TcpListener { io: pe }
}

TcpListener::raw_listener() nettcp.TcpListener {
    bits<u64> = this.io.source()
    l<nettcp.TcpListener> = null
    l = bits
    return l
}

mem AcceptOp {
    nettcp.TcpListener* listener
    nettcp.TcpStream*   out_stream
    net.SocketAddr*     out_addr
}

impl rtio.IoOp for AcceptOp {
    fn try_perform() i32, i64 {
        err<i32> = this.listener.accept()
        if err != io.Ok {
            this.out_stream = null
            this.out_addr = null
            return err, 0
        }
        this.out_stream = nettcp.tcp_accept_stream_last()
        this.out_addr = nettcp.tcp_accept_addr_last()
        return io.Ok, 0
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
        listener: this.raw_listener(),
        out_stream: null,
        out_addr: null
    }
    return new AcceptFut { io: this.io, op: op }
}

TcpListener::poll_accept(ctx<u64>) i32, TcpStream {
    op<AcceptOp> = new AcceptOp {
        listener: this.raw_listener(),
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
