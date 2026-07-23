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
use std
use runtime
use netio
use netio.net.tcp as nettcp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async TCP stream: netio source + IO-driver registration via PollEvented.
// Field `poll_ev` not `io` — `.io` / `io:` hits type-assert trap under `use io`.
mem TcpStream {
    aio.PollEvented* poll_ev
    net.SocketAddr*  peer
}

// Register an already-connected netio TcpStream with the IO driver for
// read + write readiness. `peer` is the remote address to cache. Returns
// (io.Ok, stream) or an error with a null stream (RuntimeShutdown when there
// is no active IO driver).
const TcpStream::from_netio(inner<nettcp.TcpStream>, peer<net.SocketAddr>) (i32, u64) {
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    ok_code<i32> = 1           // io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, 0
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null return shut_err, 0
    // Avoid dh.io_handle — `use io` makes `.io_*` a type-assert trap.
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 return shut_err, 0
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    holder<u64> = 0
    holder = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, 0
    if pe == null return shut_err, 0
    out<TcpStream> = new TcpStream
    out.poll_ev = pe
    out.peer = peer
    return ok_code, out.(u64)
}

// Package bridge for AcceptFut / poll_accept (Type::method illegal in async poll).
fn tcp_stream_from_netio_bits(inner<nettcp.TcpStream>, peer<net.SocketAddr>) i32, u64 {
    e<i32> = 0
    bits<u64> = 0
    e, bits = TcpStream::from_netio(inner, peer)
    return e, bits
}

// Borrow the underlying netio TcpStream (for issuing raw read/write syscalls).
TcpStream::raw_sock() nettcp.TcpStream {
    bits<u64> = this.poll_ev.source()
    s<nettcp.TcpStream> = null
    s = bits
    return s
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
    aio.PollEvented* poll_ev
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
    if this.poll_ev == null return ready, other_err, null
    c<u64> = ctx.(u64)
    werr<i32>, wev<rtio.ReadyEvent> = this.poll_ev.poll_write_ready(c)
    if werr == pend return pend
    if werr != 0 return ready, werr, null
    sock<nettcp.TcpStream> = this.stream.raw_sock()
    ok<i32>, has<i32>, soerr<i32> = sock.take_error()
    if ok != ok_code return ready, ok, null
    if has == net.Has return ready, soerr, null
    return ready, ok_code, this.stream
}

// Mother: TcpStream::connect — sync setup + ConnectFut leaf (member async
// calling nettcp.tcp_stream_connect corrupts the async frame).
const TcpStream::connect(addr<net.SocketAddr>) ConnectFut {
    cerr<i32> = nettcp.tcp_stream_connect(addr)
    if cerr != io.Ok {
        f0<ConnectFut> = new ConnectFut
        f0.poll_ev = null
        f0.stream = null
        f0.stage = -1
        return f0
    }
    inner<nettcp.TcpStream> = nettcp.tcp_stream_last()
    if inner == null {
        f1<ConnectFut> = new ConnectFut
        f1.poll_ev = null
        f1.stream = null
        f1.stage = -1
        return f1
    }
    rerr<i32>, sbits<u64> = TcpStream::from_netio(inner, addr)
    if rerr != io.Ok {
        f2<ConnectFut> = new ConnectFut
        f2.poll_ev = null
        f2.stream = null
        f2.stage = -2
        return f2
    }
    s<TcpStream> = sbits.(TcpStream)
    f<ConnectFut> = new ConnectFut
    f.poll_ev = s.poll_ev
    f.stream = s
    f.stage = 0
    return f
}

// ---- readiness -----------------------------------------------------------

// Async leaf: park until any bit in the requested interest becomes ready.
mem TcpReadyFut: async {
    aio.PollEvented* poll_ev
    i32              want_read
    i32              want_write
    aio.Ready*       result
}

TcpReadyFut::poll(ctx){
    st<i32>, err<i32>, r<aio.Ready> = aio.poll_ready_bits(this.poll_ev, this.want_read, this.want_write, ctx.(u64))
    if st == runtime.PollPending return runtime.PollPending
    if err != io.Ok return runtime.PollReady, err
    this.result = r
    return runtime.PollReady, io.Ok
}

TcpStream::ready(interest<netio.Interest>) TcpReadyFut {
    f<TcpReadyFut> = new TcpReadyFut
    f.poll_ev = this.poll_ev
    f.want_read = 0
    f.want_write = 0
    f.result = null
    if netio.interest_is_readable(interest) == 1 f.want_read = 1
    if netio.interest_is_writable(interest) == 1 f.want_write = 1
    return f
}

TcpStream::readable() TcpReadyFut {
    f<TcpReadyFut> = new TcpReadyFut
    f.poll_ev = this.poll_ev
    f.want_read = 1
    f.want_write = 0
    f.result = null
    return f
}

TcpStream::writable() TcpReadyFut {
    f<TcpReadyFut> = new TcpReadyFut
    f.poll_ev = this.poll_ev
    f.want_read = 0
    f.want_write = 1
    f.result = null
    return f
}

// ---- read / write --------------------------------------------------------

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

TcpStream::try_read(buf<io.Buf>) i32, u64 {
    sock<nettcp.TcpStream> = this.raw_sock()
    op<TcpReadOp> = new TcpReadOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.poll_ev.try_io(netio.readable_interest(), op)
    return err, val.(u64)
}

TcpStream::try_write(buf<io.Buf>) i32, u64 {
    sock<nettcp.TcpStream> = this.raw_sock()
    op<TcpWriteOp> = new TcpWriteOp { sock: sock, buf: buf }
    err<i32>, val<i64> = this.poll_ev.try_io(netio.writable_interest(), op)
    return err, val.(u64)
}

TcpStream::shutdown(how<i32>) i32 {
    sock<nettcp.TcpStream> = this.raw_sock()
    return sock.shutdown(how)
}

// Concrete read path (avoid AsyncRead api default which returns PollError).
// Ready → read_priv into NewBuf → copy into ReadBuf unfilled region.
TcpStream::poll_read_priv(ctx<u64>, buf<aio.ReadBuf>) i32 {
    rem<u64> = buf.remaining()
    if rem == 0 return runtime.PollReady
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    sock<nettcp.TcpStream> = this.raw_sock()
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(ctx)
        if rerr == pend return pend
        if rerr != 0 return runtime.PollError

        rem2<u64> = buf.remaining()
        tmp<io.Buf> = io.NewBuf(rem2.(i32))
        e<i32>, n<u64> = nettcp.tcp_stream_read_priv(sock, tmp)
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

// Concrete write path (avoid AsyncWrite api dyn).
TcpStream::poll_write_priv(ctx<u64>, buf_bits<u64>) i32, u64 {
    b<io.Buf> = io.buf_from_bits(buf_bits)
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_write_ready(ctx)
        if rerr == pend return pend, 0
        if rerr != 0 return runtime.PollError, 0

        sock<nettcp.TcpStream> = this.raw_sock()
        e<i32>, n<u64> = nettcp.tcp_stream_write_priv(sock, b)
        if e == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        if e != ok_code return runtime.PollError, 0
        return ready, n
    }
}

// Poll read into an io.Buf (bits). Avoids ReadBuf pointer-field truncation.
// Returns PollPending / PollError / PollReady; on Ready, n is bytes read.
fn stream_poll_read_buf(s<TcpStream>, ctx<u64>, buf_bits<u64>) i32, u64 {
    b<io.Buf> = io.buf_from_bits(buf_bits)
    rem<u64> = io.buf_len(b)
    if rem == 0 return runtime.PollReady, 0
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    sock<nettcp.TcpStream> = s.raw_sock()
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = s.poll_ev.poll_read_ready(ctx)
        if rerr == pend return pend, 0
        if rerr != 0 return runtime.PollError, 0

        e<i32>, n<u64> = nettcp.tcp_stream_read_priv(sock, b)
        if e == would_block {
            s.poll_ev.clear_readiness(ev)
            continue
        }
        if e != ok_code return runtime.PollError, 0
        return ready, n
    }
}

fn stream_poll_read(s<TcpStream>, ctx<u64>, buf<aio.ReadBuf>) i32 {
    return s.poll_read_priv(ctx, buf)
}

fn stream_poll_write(s<TcpStream>, ctx<u64>, buf_bits<u64>) i32, u64 {
    e<i32> = 0
    n<u64> = 0
    e, n = s.poll_write_priv(ctx, buf_bits)
    return e, n
}

impl aio.AsyncRead for TcpStream {
    fn poll_read(ctx<u64>, buf<aio.ReadBuf>) i32 {
        return this.poll_read_priv(ctx, buf)
    }
}

impl aio.AsyncWrite for TcpStream {
    fn poll_write(ctx<u64>, buf_bits<u64>) i32, u64 {
        e<i32> = 0
        n<u64> = 0
        e, n = this.poll_write_priv(ctx, buf_bits)
        return e, n
    }
    fn poll_flush(ctx<u64>) i32 {
        return runtime.PollReady
    }
    fn poll_shutdown(ctx<u64>) i32 {
        sock<nettcp.TcpStream> = this.raw_sock()
        sock.shutdown(net.ShutdownWrite)
        return runtime.PollReady
    }
}
