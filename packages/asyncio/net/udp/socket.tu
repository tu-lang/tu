// Async UDP socket. Wraps netio UdpSocket via PollEvented (bind + readiness
// + send_to / recv_from).
//
// Package asyncio.net.udp (short-name `udp`) so library `net` can be imported
// without poisoning asyncio.net. Leaf futures call poll_*_ready + raw
// syscalls (no IoOp api dyn — same trap as TcpStream read/write).
// Field `poll_ev` not `io` — `.io` is a type-assert trap under use io.

use net
use io
use runtime
use netio
use netio.net.udp as netudp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio

// Async UDP: netio source + IO-driver registration.
mem UdpSocket {
    aio.PollEvented* poll_ev
}

// Last bind result — dual-ret mem across pkgs can drop; bits bridge preferred.
LAST_UDP_SOCK<UdpSocket> = null

fn udp_socket_last() UdpSocket {
    return LAST_UDP_SOCK
}

// Bind and register for read+write readiness. Returns (io.Ok, socket bits).
const UdpSocket::bind(addr<net.SocketAddr>) (i32, u64) {
    LAST_UDP_SOCK = null
    shut_err<i32> = 0x03020005
    ok_code<i32> = 1

    err<i32>, inner<netudp.UdpSocket> = netudp.UdpSocket::bind(addr)
    if err != ok_code return err, 0
    if inner == null return shut_err, 0

    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err, 0
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null return shut_err, 0
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

    out<UdpSocket> = new UdpSocket
    out.poll_ev = pe
    LAST_UDP_SOCK = out
    return ok_code, out.(u64)
}

// Package bridge for bind (Type::method + dual-ret mem traps in async bodies).
fn udp_bind_bits(addr<net.SocketAddr>) i32, u64 {
    e<i32> = 0
    bits<u64> = 0
    e, bits = UdpSocket::bind(addr)
    return e, bits
}

// Borrow the underlying netio UdpSocket.
UdpSocket::raw_sock() netudp.UdpSocket {
    bits<u64> = this.poll_ev.source()
    s<netudp.UdpSocket> = null
    s = bits
    return s
}

// Leaf for send_to.
mem UdpSendFut: async {
    aio.PollEvented*   poll_ev
    netudp.UdpSocket*  sock
    u64                buf_bits
    net.SocketAddr*    target
    i64                byte_count
}

UdpSendFut::poll(ctx) {
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    loop {
        werr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_write_ready(ctx.(u64))
        if werr == pend return pend
        if werr != 0 return ready, werr, 0.(i64)

        buf<io.Buf> = io.buf_from_bits(this.buf_bits)
        e<i32>, n<u64> = this.sock.send_to(buf, this.target)
        if e == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        this.byte_count = n.(i64)
        return ready, e, n.(i64)
    }
    return ready, ok_code, 0.(i64)
}

// Leaf for recv_from.
mem UdpRecvFut: async {
    aio.PollEvented*   poll_ev
    netudp.UdpSocket*  sock
    u64                buf_bits
    i64                byte_count
    u64                peer_bits
}

UdpRecvFut::poll(ctx) {
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = 16908302
    ok_code<i32> = 1
    loop {
        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(ctx.(u64))
        if rerr == pend return pend
        if rerr != 0 return ready, rerr, 0.(i64), 0.(u64)

        buf<io.Buf> = io.buf_from_bits(this.buf_bits)
        e<i32>, n<u64>, addr<net.SocketAddr> = this.sock.recv_from(buf)
        if e == would_block {
            this.poll_ev.clear_readiness(ev)
            continue
        }
        bits<u64> = 0
        bits = addr
        this.peer_bits = bits
        this.byte_count = n.(i64)
        return ready, e, n.(i64), bits
    }
    return ready, ok_code, 0.(i64), 0.(u64)
}

// Return leaf for caller await.
UdpSocket::send_to(buf<io.Buf>, target<net.SocketAddr>) UdpSendFut {
    sock<netudp.UdpSocket> = this.raw_sock()
    return new UdpSendFut {
        poll_ev: this.poll_ev,
        sock: sock,
        buf_bits: io.buf_to_bits(buf),
        target: target,
        byte_count: 0
    }
}

// Return leaf for caller await.
UdpSocket::recv_from(buf<io.Buf>) UdpRecvFut {
    sock<netudp.UdpSocket> = this.raw_sock()
    return new UdpRecvFut {
        poll_ev: this.poll_ev,
        sock: sock,
        buf_bits: io.buf_to_bits(buf),
        byte_count: 0,
        peer_bits: 0
    }
}
