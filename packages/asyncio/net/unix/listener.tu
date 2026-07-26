// Async Unix-domain listener. Wraps a netio UnixListener registered with the
// current runtime's IO driver through PollEvented: bind(path) + readable-driven
// accept. Mirrors net.tcp.TcpListener.
//
// Field `poll_ev` not `io`. Accept uses poll_read_ready + accept (no IoOp).

use string
use io
use runtime
use netio
use netio.net.uds as netuds
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio

// Async unix listener: netio source + IO-driver registration for read readiness.
mem UnixListener {
    aio.PollEvented* poll_ev
}

// Last bind result when dual-ret mem drops across pkgs.
LAST_UNIX_LISTENER<UnixListener> = null

fn unix_listener_last() UnixListener {
    return LAST_UNIX_LISTENER
}

// Bind to the socket path and register for read readiness.
const UnixListener::bind(path<string.String>) (i32, u64) {
    LAST_UNIX_LISTENER = null
    err<i32>, inner<netuds.UnixListener> = netuds.UnixListener::bind(path)
    if inner == null return err, 0
    e<i32> = 0
    bits<u64> = 0
    e, bits = UnixListener::from_netio(inner)
    return e, bits
}

fn unix_listener_bind_bits(path<string.String>) i32, u64 {
    e<i32> = 0
    bits<u64> = 0
    e, bits = UnixListener::bind(path)
    return e, bits
}

// Register an already-bound netio UnixListener with the IO driver.
const UnixListener::from_netio(inner<netuds.UnixListener>) (i32, u64) {
    shut_err<i32> = 0x03020005
    ok_code<i32> = 1
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, 0
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null return shut_err, 0
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 return shut_err, 0
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    interest<netio.Interest> = netio.readable_interest()
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, 0
    if pe == null return shut_err, 0
    out<UnixListener> = new UnixListener
    out.poll_ev = pe
    LAST_UNIX_LISTENER = out
    return ok_code, out.(u64)
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
    ok_code<i32> = 1
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    other_err<i32> = 16908328
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
        rerr2<i32>, sbits<u64> = unix_stream_from_netio_bits(inner)
        if rerr2 != ok_code return ready, rerr2, null
        if sbits == 0 return ready, other_err, null
        s<UnixStream> = sbits.(UnixStream)
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
