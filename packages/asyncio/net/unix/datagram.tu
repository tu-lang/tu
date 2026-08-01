// Async Unix-domain datagram socket. Wraps a netio UnixDatagram registered
// with the current runtime's IO driver through PollEvented: bind(path) +
// readiness + datagram send/recv. Mirrors net.udp.UdpSocket.

use string
use io
use runtime
use netio
use netio.event as evsrc
use netio.net.uds as netuds
use netio.sys.uds as udsaddr
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr

// Async unix datagram socket: netio source + IO-driver registration.
mem UnixDatagram {
    aio.PollEvented* io
    u64              last_peer_bits
}

// Bind to the socket path and register for read + write readiness. Returns
// (io.Ok, socket) or an error with null.
const UnixDatagram::bind(path<string.String>) (i32, UnixDatagram) {
    err<i32>, inner<netuds.UnixDatagram> = netuds.UnixDatagram::bind(path)
    if inner == null return err, null
    e<i32>, sock<UnixDatagram> = UnixDatagram::from_netio(inner)
    return e, sock
}

// Register an already-bound netio UnixDatagram with the IO driver.
const UnixDatagram::from_netio(inner<netuds.UnixDatagram>) (i32, UnixDatagram) {
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

    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    holder<u64> = 0
    holder = inner
    src<evsrc.Source> = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, src, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 return perr, null
    return ok_code, new UnixDatagram { io: pe, last_peer_bits: 0 }
}

// Borrow the underlying netio UnixDatagram.
UnixDatagram::raw_sock() netuds.UnixDatagram {
    bits<u64> = this.io.source()
    s<netuds.UnixDatagram> = null
    s = bits
    return s
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

// IoOp for a single recv_from syscall. Peer address bits stashed in peer_bits.
mem UnixRecvFromOp {
    netuds.UnixDatagram* sock
    io.Buf*              buf
    u64                  peer_bits
}

impl rtio.IoOp for UnixRecvFromOp {
    fn try_perform() i32, i64 {
        err<i32>, n<u64>, addr<udsaddr.SocketAddr> = this.sock.recv_from(this.buf)
        this.peer_bits = addr.(u64)
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
    i64              byte_count
}

UnixSendFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_write_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.byte_count = n
    return runtime.PollReady, e
}

// Async leaf driving a read-side IoOp through PollEvented::poll_read_io.
mem UnixRecvFut: async {
    aio.PollEvented* io
    rtio.IoOp*       op
    i64              byte_count
}

UnixRecvFut::poll(ctx){
    e<i32>, n<i64> = this.io.poll_read_io(ctx.(u64), this.op)
    if e == runtime.PollPending return runtime.PollPending
    this.byte_count = n
    return runtime.PollReady, e
}

// Send `buf` to the socket at `path`. Awaits writable readiness as needed.
// Returns (io.Ok, bytes_sent) or (err, 0).
async UnixDatagram::send_to(buf<io.Buf>, path<string.String>) {
    sock<netuds.UnixDatagram> = this.raw_sock()
    op<UnixSendToOp> = new UnixSendToOp { sock: sock, buf: buf, path: path }
    f<UnixSendFut> = new UnixSendFut { io: this.io, op: op, byte_count: 0 }
    err<i32> = f.await
    nb_i64<i64> = f.byte_count
    nb<u64> = nb_i64.(u64)
    return err, nb
}

// Receive a datagram into `buf`. Peer address via last_peer() after success.
async UnixDatagram::recv_from(buf<io.Buf>) {
    sock<netuds.UnixDatagram> = this.raw_sock()
    op<UnixRecvFromOp> = new UnixRecvFromOp { sock: sock, buf: buf, peer_bits: 0 }
    f<UnixRecvFut> = new UnixRecvFut { io: this.io, op: op, byte_count: 0 }
    err<i32> = f.await
    nb_i64<i64> = f.byte_count
    nb<u64> = nb_i64.(u64)
    this.last_peer_bits = op.peer_bits
    return err, nb
}

UnixDatagram::last_peer() u64 {
    return this.last_peer_bits
}

// Receive a datagram into `buf`, discarding the peer address. Returns
// (io.Ok, bytes) or (err, 0).
async UnixDatagram::recv(buf<io.Buf>) {
    sock<netuds.UnixDatagram> = this.raw_sock()
    op<UnixRecvOp> = new UnixRecvOp { sock: sock, buf: buf }
    f<UnixRecvFut> = new UnixRecvFut { io: this.io, op: op, byte_count: 0 }
    err<i32> = f.await
    nb_i64<i64> = f.byte_count
    nb<u64> = nb_i64.(u64)
    return err, nb
}

// Non-blocking send_to: one writable-readiness check + one syscall.
UnixDatagram::try_send_to(buf<io.Buf>, path<string.String>) i32, u64 {
    sock<netuds.UnixDatagram> = this.raw_sock()
    op<UnixSendToOp> = new UnixSendToOp { sock: sock, buf: buf, path: path }
    err<i32>, val<i64> = this.io.try_io(netio.writable_interest(), op)
    return err, val.(u64)
}

// Non-blocking recv_from: one readable-readiness check + one syscall.
UnixDatagram::try_recv_from(buf<io.Buf>) i32, u64, u64 {
    sock<netuds.UnixDatagram> = this.raw_sock()
    op<UnixRecvFromOp> = new UnixRecvFromOp { sock: sock, buf: buf, peer_bits: 0 }
    err<i32>, val<i64> = this.io.try_io(netio.readable_interest(), op)
    return err, val.(u64), op.peer_bits
}
