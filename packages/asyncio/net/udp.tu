// Async UDP socket. Wraps a netio UdpSocket registered with the current
// runtime's IO driver through PollEvented: bind + readiness + datagram
// send/recv.
//
// Design note (task 15.5): the spec models this as `class UdpSocket`; per
// library-static-only it is a static `mem` holding an asyncio.io.PollEvented.

use net
use io
use runtime
use netio
use netio.net as netnet
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async UDP socket: netio source + IO-driver registration via PollEvented.
mem UdpSocket {
    aio.PollEvented* io
}

// Bind to `addr` and register with the current runtime's IO driver for
// read + write readiness. Returns (io.Ok, socket) on success, or an error
// code with a null socket (RuntimeShutdown when there is no active IO driver).
const UdpSocket::bind(addr<net.SocketAddr>) (i32, UdpSocket) {
    err<i32>, inner<netnet.UdpSocket> = netnet.UdpSocket::bind(addr)
    if inner == null return err, null
    return UdpSocket::from_netio(inner)
}

// Register an already-bound netio UdpSocket with the IO driver. Returns
// (io.Ok, socket) or an error with null.
const UdpSocket::from_netio(inner<netnet.UdpSocket>) (i32, UdpSocket) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver.(rt.DriverHandle)
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = aio.interest_add(aio.Interest::readable(), aio.Interest::writable())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new UdpSocket { io: pe }
}

// Borrow the underlying netio UdpSocket (for issuing raw send/recv syscalls).
UdpSocket::netio_sock() netnet.UdpSocket {
    return this.io.source()
}

// ---- readiness -----------------------------------------------------------

// Async leaf: park until any bit in the requested interest becomes ready. The
// ready bits are stashed in `result`; poll returns io.Ok once non-empty.
mem UdpReadyFut: async {
    aio.PollEvented* io          // borrowed registration
    i32              want_read   // 1 when the caller asked for read readiness
    i32              want_write  // 1 when the caller asked for write readiness
    aio.Ready*       result      // filled with the ready bits on completion
}

// Poll read/write readiness per the requested interest, OR-ing whatever the
// driver reports. Returns PollReady once any bit is set (result filled), a
// driver error code verbatim, or PollPending while nothing is ready yet.
UdpReadyFut::poll(ctx){
    c<u64> = ctx.(u64)
    bits<i32> = 0
    if this.want_read == 1 {
        rerr<i32>, rev<rtio.ReadyEvent> = this.io.poll_read_ready(c)
        if rerr == 0 {
            bits = bits | rev.ready.bits
        } else if rerr != runtime.PollPending {
            return runtime.PollReady, rerr
        }
    }
    if this.want_write == 1 {
        werr<i32>, wev<rtio.ReadyEvent> = this.io.poll_write_ready(c)
        if werr == 0 {
            bits = bits | wev.ready.bits
        } else if werr != runtime.PollPending {
            return runtime.PollReady, werr
        }
    }
    if bits != 0 {
        this.result = aio.Ready::from_bits(bits)
        return runtime.PollReady, io.Ok
    }
    return runtime.PollPending
}

// Await read and/or write readiness for `interest`. Returns (io.Ok, ready)
// with the ready bits, or (err, null) on driver error.
async UdpSocket::ready(interest<netio.Interest>) i32, aio.Ready {
    f<UdpReadyFut> = new UdpReadyFut {
        io: this.io,
        want_read: 0,
        want_write: 0,
        result: null
    }
    if interest.is_readable() f.want_read = 1
    if interest.is_writable() f.want_write = 1
    err<i32> = f.await
    return err, f.result
}

// ---- send_to / recv_from -------------------------------------------------

// IoOp for a single send_to syscall. Returns (err, bytes); err == io.WouldBlock
// makes PollEvented retry after the next writable readiness.
mem SendToOp {
    netnet.UdpSocket* sock
    io.Buf*           buf
    net.SocketAddr*   addr
}

impl rtio.IoOp for SendToOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.send_to(this.buf, this.addr)
        return err, n.(i64)
    }
}

// IoOp for a single recv_from syscall. The peer address is stashed in
// addr_out; try_perform returns (err, bytes).
mem RecvFromOp {
    netnet.UdpSocket* sock
    io.Buf*           buf
    net.SocketAddr*   addr_out
}

impl rtio.IoOp for RecvFromOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64>, addr<net.SocketAddr> = this.sock.recv_from(this.buf)
        this.addr_out = addr
        return err, n.(i64)
    }
}

// Async leaf driving a write-side IoOp through PollEvented::poll_write_io.
mem SendToFut: async {
    aio.PollEvented* io
    SendToOp*        op
    i64              size
}

SendToFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_write_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    return runtime.PollReady, e
}

// Async leaf driving a read-side IoOp through PollEvented::poll_read_io.
mem RecvFromFut: async {
    aio.PollEvented* io
    RecvFromOp*      op
    i64              size
}

RecvFromFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    return runtime.PollReady, e
}

// Send `buf` to `addr`. Awaits writable readiness as needed. Returns
// (io.Ok, bytes_sent) or (err, 0).
async UdpSocket::send_to(buf<io.Buf>, addr<net.SocketAddr>) i32, u64 {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp { sock: sock, buf: buf, addr: addr }
    f<SendToFut> = new SendToFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64)
}

// Receive a datagram into `buf`. Awaits readable readiness as needed. Returns
// (io.Ok, bytes, peer_addr) or (err, 0, null).
async UdpSocket::recv_from(buf<io.Buf>) i32, u64, net.SocketAddr {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp { sock: sock, buf: buf, addr_out: null }
    f<RecvFromFut> = new RecvFromFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64), op.addr_out
}

// Non-blocking send_to: one writable-readiness check + one syscall. Returns
// (io.Ok, bytes), (io.WouldBlock, 0) when not ready, or (err, 0).
UdpSocket::try_send_to(buf<io.Buf>, addr<net.SocketAddr>) i32, u64 {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp { sock: sock, buf: buf, addr: addr }
    interest<netio.Interest> = aio.Interest::writable()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    return err, val.(u64)
}

// Non-blocking recv_from: one readable-readiness check + one syscall. Returns
// (io.Ok, bytes, peer_addr), (io.WouldBlock, 0, null), or (err, 0, null).
UdpSocket::try_recv_from(buf<io.Buf>) i32, u64, net.SocketAddr {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp { sock: sock, buf: buf, addr_out: null }
    interest<netio.Interest> = aio.Interest::readable()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    return err, val.(u64), op.addr_out
}
