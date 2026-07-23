// Async TCP listener. Wraps a netio TcpListener registered with the current
// runtime's IO driver through PollEvented: bind + readable-driven accept.
//
// accept() returns AcceptFut (sync), same pattern as TcpStream::connect →
// ConnectFut. An `async` wrapper would make one `.await` only construct the
// leaf and never poll it (call sites use accept().await for the result).
// AcceptFut::poll mirrors mother poll_accept (ready + accept + clear on
// WouldBlock) without IoOp api dispatch.

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
    aio.PollEvented* poll_ev
}

const TcpListener::bind(addr<net.SocketAddr>) (i32, TcpListener) {
    err<i32> = nettcp.TcpListener::bind(addr)
    if err != io.Ok return err, null
    inner<nettcp.TcpListener> = nettcp.tcp_listener_last()
    if inner == null return err, null
    lerr<i32>, lbits<u64> = TcpListener::from_netio(inner)
    if lerr != io.Ok return lerr, null
    return io.Ok, lbits.(TcpListener)
}

const TcpListener::from_netio(inner<nettcp.TcpListener>) (i32, u64) {
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    ok_code<i32> = 1           // io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null {
        return shut_err, 0
    }
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null {
        return shut_err, 0
    }
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 {
        return shut_err, 0
    }
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    interest<netio.Interest> = netio.readable_interest()
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 {
        return perr, 0
    }
    out<TcpListener> = new TcpListener
    out.poll_ev = pe
    return ok_code, out.(u64)
}

TcpListener::raw_listener() nettcp.TcpListener {
    bits<u64> = this.poll_ev.source()
    l<nettcp.TcpListener> = null
    l = bits
    return l
}

// Leaf future for accept().await — mother poll_accept loop.
mem AcceptFut: async {
    aio.PollEvented*     poll_ev
    nettcp.TcpListener*  listener
}

AcceptFut::poll(ctx){
    ok_code<i32> = 1
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302 // io.WouldBlock
    c<u64> = ctx.(u64)
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(c)
        if rerr == pend return pend
        if rerr != 0 return ready, rerr, null

        acc_err<i32> = this.listener.accept()
        if acc_err == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if acc_err != ok_code return ready, acc_err, null

        inner<nettcp.TcpStream> = nettcp.tcp_accept_stream_last()
        peer<net.SocketAddr> = nettcp.tcp_accept_addr_last()
        if inner == null return ready, 16908328, null // io.Other
        // Package bridge: Type::method static call fails inside async poll.
        rerr2<i32>, sbits<u64> = tcp_stream_from_netio_bits(inner, peer)
        if rerr2 != ok_code return ready, rerr2, null
        if sbits == 0 return ready, 16908328, null
        s<TcpStream> = sbits.(TcpStream)
        return ready, ok_code, s
    }
}

// Sync factory (like TcpStream::connect); callers use accept().await once.
TcpListener::accept() AcceptFut {
    f<AcceptFut> = new AcceptFut
    f.poll_ev = this.poll_ev
    f.listener = this.raw_listener()
    return f
}

// Mother: poll_accept — same ready/accept/clear loop as AcceptFut::poll.
TcpListener::poll_accept(ctx<u64>) i32, TcpStream {
    ok_code<i32> = 1
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(ctx)
        if rerr == pend return pend, null
        if rerr != 0 return runtime.PollError, null

        listener<nettcp.TcpListener> = this.raw_listener()
        acc_err<i32> = listener.accept()
        if acc_err == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if acc_err != ok_code return runtime.PollError, null

        inner<nettcp.TcpStream> = nettcp.tcp_accept_stream_last()
        peer<net.SocketAddr> = nettcp.tcp_accept_addr_last()
        rerr2<i32>, sbits<u64> = tcp_stream_from_netio_bits(inner, peer)
        if rerr2 != ok_code return runtime.PollError, null
        s<TcpStream> = sbits.(TcpStream)
        return ready, s
    }
}
