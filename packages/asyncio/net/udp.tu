// Async UDP socket. Wraps a netio UdpSocket registered with the current
// runtime's IO driver through PollEvented: bind + readiness + datagram
// send/recv.
//
// Design note (task 15.5): the spec models this as `class UdpSocket`; per
// library-static-only it is a static `mem` holding an asyncio.io.PollEvented.

use net as libnet
use io as libio
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
// read + write readiness. Returns (libio.Ok, socket) on success, or an error
// code with a null socket (RuntimeShutdown when there is no active IO driver).
const UdpSocket::bind(addr<libnet.SocketAddr>) (i32, UdpSocket) {
    err<i32>, inner<netnet.UdpSocket> = netnet.UdpSocket::bind(addr)
    if inner == null return err, null
    return UdpSocket::from_netio(inner)
}

// Register an already-bound netio UdpSocket with the IO driver. Returns
// (libio.Ok, socket) or an error with null.
const UdpSocket::from_netio(inner<netnet.UdpSocket>) (i32, UdpSocket) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = aio.interest_add(aio.readable(), aio.writable())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return libio.Ok, new UdpSocket { io: pe }
}

// Borrow the underlying netio UdpSocket (for issuing raw send/recv syscalls).
UdpSocket::netio_sock() netnet.UdpSocket {
    return this.io.source()
}

// ---- readiness -----------------------------------------------------------

// Async leaf: park until any bit in the requested interest becomes ready. The
// ready bits are stashed in `result`; poll returns libio.Ok once non-empty.
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
    st<i32>, err<i32>, r<aio.Ready> = aio.poll_ready_bits(this.io, this.want_read, this.want_write, ctx.(u64))
    if st == runtime.PollPending return runtime.PollPending
    if err != libio.Ok return runtime.PollReady, err
    this.result = r
    return runtime.PollReady, libio.Ok
}

// Await read and/or write readiness for `interest`. Returns (libio.Ok, ready)
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

// IoOp for a single send_to syscall. Returns (err, bytes); err == libio.WouldBlock
// makes PollEvented retry after the next writable readiness.
mem SendToOp {
    netnet.UdpSocket* sock
    libio.Buf*           buf
    libnet.SocketAddr*   addr
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
    libio.Buf*           buf
    libnet.SocketAddr*   addr_out
}

impl rtio.IoOp for RecvFromOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64>, addr<libnet.SocketAddr> = this.sock.recv_from(this.buf)
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
// (libio.Ok, bytes_sent) or (err, 0).
async UdpSocket::send_to(buf<libio.Buf>, addr<libnet.SocketAddr>) i32, u64 {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp { sock: sock, buf: buf, addr: addr }
    f<SendToFut> = new SendToFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64)
}

// Receive a datagram into `buf`. Awaits readable readiness as needed. Returns
// (libio.Ok, bytes, peer_addr) or (err, 0, null).
async UdpSocket::recv_from(buf<libio.Buf>) i32, u64, libnet.SocketAddr {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp { sock: sock, buf: buf, addr_out: null }
    f<RecvFromFut> = new RecvFromFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64), op.addr_out
}

// Non-blocking send_to: one writable-readiness check + one syscall. Returns
// (libio.Ok, bytes), (libio.WouldBlock, 0) when not ready, or (err, 0).
UdpSocket::try_send_to(buf<libio.Buf>, addr<libnet.SocketAddr>) i32, u64 {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp { sock: sock, buf: buf, addr: addr }
    interest<netio.Interest> = aio.writable()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    return err, val.(u64)
}

// Non-blocking recv_from: one readable-readiness check + one syscall. Returns
// (libio.Ok, bytes, peer_addr), (libio.WouldBlock, 0, null), or (err, 0, null).
UdpSocket::try_recv_from(buf<libio.Buf>) i32, u64, libnet.SocketAddr {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp { sock: sock, buf: buf, addr_out: null }
    interest<netio.Interest> = aio.readable()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    return err, val.(u64), op.addr_out
}
