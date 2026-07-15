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

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
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

// IoOp for a single send_to syscall. Foreign pointers stored as u64.
mem SendToOp {
    u64 sock_bits
    u64 buf_bits
    u64 addr_bits
}

impl rtio.IoOp for SendToOp {
    fn try_perform() i32, i64 {
        sock<netnet.UdpSocket> = netnet.udp_socket_from_bits(this.sock_bits)
        buf<libio.Buf> = libio.buf_from_bits(this.buf_bits)
        addr<libnet.SocketAddr> = libnet.socket_addr_from_bits(this.addr_bits)
        err<i32>, n<u64> = sock.send_to(buf, addr)
        return err, n.(i64)
    }
}

mem RecvFromOp {
    u64 sock_bits
    u64 buf_bits
    u64 addr_out_bits
}

impl rtio.IoOp for RecvFromOp {
    fn try_perform() i32, i64 {
        sock<netnet.UdpSocket> = netnet.udp_socket_from_bits(this.sock_bits)
        buf<libio.Buf> = libio.buf_from_bits(this.buf_bits)
        err<i32>, n<u64>, addr<libnet.SocketAddr> = sock.recv_from(buf)
        this.addr_out_bits = libnet.socket_addr_to_bits(addr)
        return err, n.(i64)
    }
}

mem SendToFut: async {
    aio.PollEvented* io
    SendToOp*        op
    i64              size
}

SendToFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_write_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    return runtime.PollReady, e, n.(u64)
}

mem RecvFromFut: async {
    aio.PollEvented* io
    RecvFromOp*      op
    i64              size
}

RecvFromFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    peer = libnet.socket_addr_from_bits(this.op.addr_out_bits)
    return runtime.PollReady, e, n.(u64), peer
}

// Mother: ready / send_to / recv_from — return leaf futures (no member await).
UdpSocket::ready(interest<netio.Interest>) UdpReadyFut {
    f<UdpReadyFut> = new UdpReadyFut {
        io: this.io,
        want_read: 0,
        want_write: 0,
        result: null
    }
    if netio.interest_is_readable(interest) == 1 f.want_read = 1
    if netio.interest_is_writable(interest) == 1 f.want_write = 1
    return f
}

UdpSocket::send_to(buf<libio.Buf>, addr<libnet.SocketAddr>) SendToFut {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp {
        sock_bits: netnet.udp_socket_to_bits(sock),
        buf_bits: libio.buf_to_bits(buf),
        addr_bits: libnet.socket_addr_to_bits(addr)
    }
    return new SendToFut { io: this.io, op: op, size: 0 }
}

UdpSocket::recv_from(buf<libio.Buf>) RecvFromFut {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp {
        sock_bits: netnet.udp_socket_to_bits(sock),
        buf_bits: libio.buf_to_bits(buf),
        addr_out_bits: 0
    }
    return new RecvFromFut { io: this.io, op: op, size: 0 }
}

// Non-blocking send_to: one writable-readiness check + one syscall. Returns
// (libio.Ok, bytes), (libio.WouldBlock, 0) when not ready, or (err, 0).
UdpSocket::try_send_to(buf<libio.Buf>, addr<libnet.SocketAddr>) i32, u64 {
    sock<netnet.UdpSocket> = this.io.source()
    op<SendToOp> = new SendToOp {
        sock_bits: netnet.udp_socket_to_bits(sock),
        buf_bits: libio.buf_to_bits(buf),
        addr_bits: libnet.socket_addr_to_bits(addr)
    }
    interest<netio.Interest> = netio.writable_interest()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    return err, val.(u64)
}

// Non-blocking recv_from: one readable-readiness check + one syscall. Returns
// (libio.Ok, bytes, peer_addr), (libio.WouldBlock, 0, null), or (err, 0, null).
UdpSocket::try_recv_from(buf<libio.Buf>) i32, u64, libnet.SocketAddr {
    sock<netnet.UdpSocket> = this.io.source()
    op<RecvFromOp> = new RecvFromOp {
        sock_bits: netnet.udp_socket_to_bits(sock),
        buf_bits: libio.buf_to_bits(buf),
        addr_out_bits: 0
    }
    interest<netio.Interest> = netio.readable_interest()
    err<i32>, val<i64> = this.io.try_io(interest, op)
    peer = libnet.socket_addr_from_bits(op.addr_out_bits)
    return err, val.(u64), peer
}
