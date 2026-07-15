// Async Unix-domain datagram socket. Wraps a netio UnixDatagram registered
// with the current runtime's IO driver through PollEvented: bind(path) +
// readiness + datagram send/recv. Mirrors net.udp.UdpSocket.

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

// Async unix datagram socket: netio source + IO-driver registration.
mem UnixDatagram {
    aio.PollEvented* io
}

// Bind to the socket path and register for read + write readiness. Returns
// (io.Ok, socket) or an error with null.
const UnixDatagram::bind(path<string.String>) (i32, UnixDatagram) {
    err<i32>, inner<netuds.UnixDatagram> = netuds.UnixDatagram::bind(path)
    if inner == null return err, null
    return UnixDatagram::from_netio(inner)
}

// Register an already-bound netio UnixDatagram with the IO driver.
const UnixDatagram::from_netio(inner<netuds.UnixDatagram>) (i32, UnixDatagram) {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rc.driver
    if dh == null || dh.io_handle == null return aerr.RuntimeShutdown, null

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(inner, interest, rc.sched, dh.io_handle)
    if perr != 0 return perr, null
    return io.Ok, new UnixDatagram { io: pe }
}

// Borrow the underlying netio UnixDatagram.
UnixDatagram::netio_sock() netuds.UnixDatagram {
    return this.io.source()
}

// IoOp for a single send_to syscall to `path`.
mem UnixSendToOp {
    netuds.UnixDatagram* sock
    io.Buf*              buf
    string.String*       path
}

impl rtio.IoOp for UnixSendToOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.send_to(this.buf, this.path)
        return err, n.(i64)
    }
}

// IoOp for a single recv_from syscall. The peer address is stashed in addr_out.
mem UnixRecvFromOp {
    netuds.UnixDatagram* sock
    io.Buf*              buf
    udsaddr.SocketAddr*  addr_out
}

impl rtio.IoOp for UnixRecvFromOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64>, addr<udsaddr.SocketAddr> = this.sock.recv_from(this.buf)
        this.addr_out = addr
        return err, n.(i64)
    }
}

// IoOp for a single connectionless recv syscall (peer address discarded).
mem UnixRecvOp {
    netuds.UnixDatagram* sock
    io.Buf*              buf
}

impl rtio.IoOp for UnixRecvOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64> = this.sock.recv(this.buf)
        return err, n.(i64)
    }
}

// Async leaf driving a write-side IoOp through PollEvented::poll_write_io.
mem UnixSendFut: async {
    aio.PollEvented* io
    rtio.IoOp*       op
    i64              size
}

UnixSendFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_write_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    return runtime.PollReady, e
}

// Async leaf driving a read-side IoOp through PollEvented::poll_read_io.
mem UnixRecvFut: async {
    aio.PollEvented* io
    rtio.IoOp*       op
    i64              size
}

UnixRecvFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.size = n
    return runtime.PollReady, e
}

// Send `buf` to the socket at `path`. Awaits writable readiness as needed.
// Returns (io.Ok, bytes_sent) or (err, 0).
async UnixDatagram::send_to(buf<io.Buf>, path<string.String>) i32, u64 {
    sock<netuds.UnixDatagram> = this.io.source()
    op<UnixSendToOp> = new UnixSendToOp { sock: sock, buf: buf, path: path }
    f<UnixSendFut> = new UnixSendFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64)
}

// Receive a datagram into `buf`, returning the peer address. Awaits readable
// readiness as needed. Returns (io.Ok, bytes, peer_addr) or (err, 0, null).
async UnixDatagram::recv_from(buf<io.Buf>) i32, u64, udsaddr.SocketAddr {
    sock<netuds.UnixDatagram> = this.io.source()
    op<UnixRecvFromOp> = new UnixRecvFromOp { sock: sock, buf: buf, addr_out: null }
    f<UnixRecvFut> = new UnixRecvFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64), op.addr_out
}

// Receive a datagram into `buf`, discarding the peer address. Returns
// (io.Ok, bytes) or (err, 0).
async UnixDatagram::recv(buf<io.Buf>) i32, u64 {
    sock<netuds.UnixDatagram> = this.io.source()
    op<UnixRecvOp> = new UnixRecvOp { sock: sock, buf: buf }
    f<UnixRecvFut> = new UnixRecvFut { io: this.io, op: op, size: 0 }
    err<i32> = f.await
    return err, f.size.(u64)
}

// Non-blocking send_to: one writable-readiness check + one syscall.
UnixDatagram::try_send_to(buf<io.Buf>, path<string.String>) i32, u64 {
    sock<netuds.UnixDatagram> = this.io.source()
    op<UnixSendToOp> = new UnixSendToOp { sock: sock, buf: buf, path: path }
    err<i32>, val<i64> = this.io.try_io(netio.writable_interest(), op)
    return err, val.(u64)
}

// Non-blocking recv_from: one readable-readiness check + one syscall.
UnixDatagram::try_recv_from(buf<io.Buf>) i32, u64, udsaddr.SocketAddr {
    sock<netuds.UnixDatagram> = this.io.source()
    op<UnixRecvFromOp> = new UnixRecvFromOp { sock: sock, buf: buf, addr_out: null }
    err<i32>, val<i64> = this.io.try_io(netio.readable_interest(), op)
    return err, val.(u64), op.addr_out
}
