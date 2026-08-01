// Async Unix-domain listener. Wraps a netio UnixListener registered with the
// current runtime's IO driver through PollEvented: bind(path) + readable-driven
// accept. Mirrors net.tcp.TcpListener.
//
// Field `poll_ev` not `io`. Accept uses poll_read_ready + accept (no IoOp).

use string
use io
use runtime
use netio
use netio.event as evsrc
use netio.net.uds as netuds
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async unix listener: netio source + IO-driver registration for read readiness.
mem UnixListener {
    aio.PollEvented* poll_ev
}

// Last bind result (debug / fallback handle).
LAST_UNIX_LISTENER<UnixListener> = null

fn unix_listener_last() UnixListener {
    return LAST_UNIX_LISTENER
}

// Bind to the socket path and register for read readiness.
const UnixListener::bind(path<string.String>) (i32, UnixListener) {
    LAST_UNIX_LISTENER = null
    err<i32>, inner<netuds.UnixListener> = netuds.UnixListener::bind(path)
    if inner == null return err, null
    e<i32>, listener<UnixListener> = UnixListener::from_netio(inner)
    return e, listener
}

fn unix_listener_bind(path<string.String>) i32, UnixListener {
    e<i32> = 0
    l<UnixListener> = null
    e, l = UnixListener::bind(path)
    return e, l
}

// Register an already-bound netio UnixListener with the IO driver.
const UnixListener::from_netio(inner<netuds.UnixListener>) (i32, UnixListener) {
    shut_err<i32> = aerr.RuntimeShutdown
    ok_code<i32> = io.Ok
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
    src<evsrc.Source> = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, src, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, null
    if pe == null return shut_err, null
    out<UnixListener> = new UnixListener
    out.poll_ev = pe
    LAST_UNIX_LISTENER = out
    return ok_code, out
}

// Borrow the underlying netio UnixListener.
UnixListener::raw_listener() netuds.UnixListener {
    bits<u64> = this.poll_ev.source()
    s<netuds.UnixListener> = null
    s = bits
    return s
}

// Leaf future for accept().await — the design poll_accept loop (no IoOp).
mem UnixAcceptFut: async {
    aio.PollEvented*      poll_ev
    netuds.UnixListener*  listener
}

UnixAcceptFut::poll(ctx){
    ok_code<i32> = io.Ok
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = io.WouldBlock
    other_err<i32> = io.Other
    c<u64> = ctx.(u64)
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(c)
        if rerr == pend return pend
        if rerr != 0 return ready, rerr, null

        acc_err<i32>, inner<netuds.UnixStream>, _ = this.listener.accept()
        if acc_err == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if acc_err != ok_code return ready, acc_err, null
        if inner == null return ready, other_err, null
        rerr2<i32>, s<UnixStream> = unix_stream_from_netio(inner)
        if rerr2 != ok_code return ready, rerr2, null
        if s == null return ready, other_err, null
        return ready, ok_code, s
    }
}

// Sync factory; callers use accept().await once.
UnixListener::accept() UnixAcceptFut {
    f<UnixAcceptFut> = new UnixAcceptFut
    f.poll_ev = this.poll_ev
    f.listener = this.raw_listener()
    return f
}
