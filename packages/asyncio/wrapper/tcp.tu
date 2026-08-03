// Dynamic-facing TCP surface: class shells + sync factories returning engine leaf futures.
// Await those futures in the *caller's* package-level async (main/test file).
// Awaiting (i32, Mem) inside this imported package drops the Mem to null.

use io
use std
use string
use net
use asyncio.util
use asyncio.net.tcp as tcp
use asyncio.io as aio
use asyncio.io.util as ioutil
use asyncio.wrapper.types as wtypes

fn parse_addr_dyn(addr) (i32, net.SocketAddr) {
    addr_s<string.String> = dyn_string(addr)
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, sa<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    return perr, sa
}

fn tcp_accept_leaf(bits<u64>) tcp.AcceptFut {
    l<tcp.TcpListener> = bits.(tcp.TcpListener)
    return l.accept()
}

fn tcp_connect_leaf(addr<net.SocketAddr>) tcp.ConnectFut {
    return tcp.TcpStream::connect(addr)
}

fn tcp_write_leaf(bits<u64>, buf<io.Buf>) ioutil.WriteAll {
    st<tcp.TcpStream> = bits.(tcp.TcpStream)
    w<aio.AsyncWrite> = st
    return ioutil.write_all(w, buf)
}

fn tcp_read_leaf(bits<u64>, rb<aio.ReadBuf>) ioutil.Read {
    st<tcp.TcpStream> = bits.(tcp.TcpStream)
    return ioutil.read(st, rb)
}

fn tcp_close_leaf(bits<u64>) {
    if bits == 0 {
        return
    }
    st<tcp.TcpStream> = bits.(tcp.TcpStream)
    if st.poll_ev != null {
        st.poll_ev.close()
    }
}

func listen(addr) {
    perr<i32>, sa<net.SocketAddr> = parse_addr_dyn(addr)
    if perr != io.Ok {
        return perr, null
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(sa)
    if berr != io.Ok {
        return berr, null
    }
    return 0, wtypes.listenerFrom(listener)
}

func dial() {
    return wtypes.dial()
}

func streamFrom(engine_obj) {
    return wtypes.streamFrom(engine_obj)
}

// Returns AcceptFut. Caller: aerr, peer = wrap.takeConn(lis).await; st = wrap.streamFrom(peer)
fn takeConn(lis) tcp.AcceptFut {
    bits<u64> = lis.raw
    return tcp_accept_leaf(bits)
}

// Returns ConnectFut.
fn dialTo(addr) tcp.ConnectFut {
    perr<i32>, sa<net.SocketAddr> = parse_addr_dyn(addr)
    if perr != io.Ok {
        perr2<i32>, sa2<net.SocketAddr> = parse_addr_dyn(*"127.0.0.1:1")
        return tcp_connect_leaf(sa2)
    }
    return tcp_connect_leaf(sa)
}

// Returns WriteAll future.
fn sendStr(st, s) ioutil.WriteAll {
    bits<u64> = st.raw
    buf<io.Buf> = dyn_buf(s)
    return tcp_write_leaf(bits, buf)
}

// Returns (Read future, owned buffer). Caller awaits Read then recvDone.
fn recvStr(st, max_n) (ioutil.Read, io.Buf) {
    bits<u64> = st.raw
    n_i<i32> = max_n
    own<io.Buf> = io.NewBuf(n_i)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), n_i)
    return tcp_read_leaf(bits, rb), own
}

func recvDone(own, rerr, rn) {
    if rerr != io.Ok {
        return ""
    }
    return buf_to_dyn_string(own, rn)
}

func closeStream(st) {
    bits<u64> = st.raw
    tcp_close_leaf(bits)
    st.raw = 0
}
