// Async Unix-domain stream socket. Wraps a netio UnixStream registered with
// the current runtime's IO driver through PollEvented: connect + readiness +
// byte read/write. Mirrors net.tcp.TcpStream with a path-based connect.
//
// Field `poll_ev` not `io` — `.io` is a type-assert trap under use io.
// Read/write use poll_*_ready + raw syscalls (no IoOp api dyn).

use string
use net
use io
use std
use runtime
use netio
use netio.net.uds as netuds
use asyncio.io as aio
use asyncio.io.util as ioutil
use asyncio.runtime as rt
use asyncio.runtime.io as rtio

// Async unix stream: netio source + IO-driver registration via PollEvented.
mem UnixStream {
    aio.PollEvented* poll_ev
}

// Register an already-connected netio UnixStream with the IO driver.
// Returns (io.Ok, stream) or an error with null.
const UnixStream::from_netio(inner<netuds.UnixStream>) (i32, UnixStream) {
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

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, null
    if pe == null return shut_err, null
    out<UnixStream> = new UnixStream
    out.poll_ev = pe
    return ok_code, out
}

fn unix_stream_from_netio(inner<netuds.UnixStream>) i32, UnixStream {
    e<i32> = 0
    s<UnixStream> = null
    e, s = UnixStream::from_netio(inner)
    return e, s
}

// Borrow the underlying netio UnixStream.
UnixStream::raw_sock() netuds.UnixStream {
    bits<u64> = this.poll_ev.source()
    s<netuds.UnixStream> = null
    s = bits
    return s
}

// ---- connect -------------------------------------------------------------

// Async leaf: write readiness + SO_ERROR. poll returns (PollReady, err, stream).
mem UnixConnectFut: async {
    aio.PollEvented* poll_ev
    UnixStream*      stream
    i32              stage
}

UnixConnectFut::poll(ctx){
    other_err<i32> = 16908328
    shut_err<i32> = 0x03020005
    ok_code<i32> = 1
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    if this.stage == -1 return ready, other_err, null
    if this.stage == -2 return ready, shut_err, null
    if this.poll_ev == null return ready, other_err, null
    c<u64> = ctx.(u64)
    werr<i32>, wev<rtio.ReadyEvent> = this.poll_ev.poll_write_ready(c)
    if werr == pend return pend
    if werr != 0 return ready, werr, null
    sock<netuds.UnixStream> = this.stream.raw_sock()
    ok<i32>, has<i32>, soerr<i32> = sock.take_error()
    if ok != ok_code return ready, ok, null
    if has == net.Has return ready, soerr, null
    return ready, ok_code, this.stream
}

// Sync setup + leaf (no member async+await).
const UnixStream::connect(path<string.String>) UnixConnectFut {
    cerr<i32>, inner<netuds.UnixStream> = netuds.UnixStream::connect(path)
    if cerr != io.Ok || inner == null {
        f0<UnixConnectFut> = new UnixConnectFut
        f0.poll_ev = null
        f0.stream = null
        f0.stage = -1
        return f0
    }
    rerr<i32>, s<UnixStream> = UnixStream::from_netio(inner)
    if rerr != io.Ok {
        f1<UnixConnectFut> = new UnixConnectFut
        f1.poll_ev = null
        f1.stream = null
        f1.stage = -2
        return f1
    }
    f<UnixConnectFut> = new UnixConnectFut
    f.poll_ev = s.poll_ev
    f.stream = s
    f.stage = 0
    return f
}

// ---- read / write (no IoOp) ----------------------------------------------

// Concrete read into ReadBuf (mirrors TcpStream::poll_read_priv).
UnixStream::poll_read_priv(ctx<u64>, buf<aio.ReadBuf>) i32 {
    rem<u64> = buf.remaining()
    if rem == 0 return runtime.PollReady
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    sock<netuds.UnixStream> = this.raw_sock()
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(ctx)
        if rerr == pend return pend
        if rerr != 0 return runtime.PollError

        rem2<u64> = buf.remaining()
        if rem2 == 0 return ready
        tmp<io.Buf> = io.NewBuf(rem2.(i32))
        e<i32>, n<u64> = sock.read(tmp)
        if e == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if e != ok_code return runtime.PollError
        if n > 0 {
            dst<u8*> = buf.unfilled_ptr()
            src<i8*> = io.buf_ptr(tmp)
            sp<u8*> = null
            sp = src
            std.memcpy(dst, sp, n)
            buf.advance(n)
        }
        return ready
    }
}

UnixStream::poll_write_priv(ctx<u64>, b<io.Buf>) i32, u64 {
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_write_ready(ctx)
        if rerr == pend return pend, 0
        if rerr != 0 return runtime.PollError, 0

        sock<netuds.UnixStream> = this.raw_sock()
        e<i32>, n<u64> = sock.write(b)
        if e == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if e != ok_code return runtime.PollError, 0
        return ready, n
    }
}

UnixStream::shutdown(how<i32>) i32 {
    sock<netuds.UnixStream> = this.raw_sock()
    return sock.shutdown(how)
}

impl aio.AsyncRead for UnixStream {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.poll_read_priv(ctx, buf)
    }
}

impl ioutil.AsyncWrite for UnixStream {
    fn poll_write(ctx<u64>, buf<io.Buf>) i32, u64 {
        e<i32> = 0
        n<u64> = 0
        e, n = this.poll_write_priv(ctx, buf)
        return e, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        sock<netuds.UnixStream> = this.raw_sock()
        sock.shutdown(net.ShutdownWrite)
        return runtime.PollReady
    }
}
