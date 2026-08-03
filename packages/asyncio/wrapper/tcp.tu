// Dynamic-facing TCP surface: camelCase func / async, dyn in and out.
// Engine Mem awaits stay inside this package; examples only see class shells
// and dynamic error codes / strings.

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

// Bind and return (err, Listener class). Dyn address string.
func listen(addr) {
    perr<i32>, sa<net.SocketAddr> = parse_addr_dyn(addr)
    if perr != io.Ok {
        return int(perr), null
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(sa)
    if berr != io.Ok {
        return int(berr), null
    }
    out = wtypes.listenerFrom(listener)
    return 0, out
}

func dial() {
    return wtypes.dial()
}

func streamFrom(engine_obj) {
    return wtypes.streamFrom(engine_obj)
}

// Accept one connection; returns (err, Stream class).
async takeConn(lis) {
    bits<u64> = lis.raw
    afut<tcp.AcceptFut> = tcp_accept_leaf(bits)
    aerr<i32>, peer<tcp.TcpStream> = afut.await
    if aerr != io.Ok {
        return int(aerr), null
    }
    if peer == null {
        return int(io.Other), null
    }
    st = wtypes.streamFrom(peer)
    return 0, st
}

// Dial; returns (err, Stream class).
async dialTo(addr) {
    perr<i32>, sa<net.SocketAddr> = parse_addr_dyn(addr)
    if perr != io.Ok {
        return int(perr), null
    }
    cfut<tcp.ConnectFut> = tcp_connect_leaf(sa)
    cerr<i32>, peer<tcp.TcpStream> = cfut.await
    if cerr != io.Ok {
        return int(cerr), null
    }
    if peer == null {
        return int(io.Other), null
    }
    st = wtypes.streamFrom(peer)
    return 0, st
}

// Write full dyn string; returns (err, ""). err==0 on success.
async sendStr(st, s) {
    bits<u64> = st.raw
    buf<io.Buf> = dyn_buf(s)
    wfut<ioutil.WriteAll> = tcp_write_leaf(bits, buf)
    werr<i32> = wfut.await
    if werr != io.Ok {
        return int(werr), ""
    }
    return 0, ""
}

// Read up to max_n bytes; returns (err, dyn string). err==0 on success.
async recvStr(st, max_n) {
    bits<u64> = st.raw
    n_i<i32> = dyn_i32(max_n)
    if n_i <= 0 {
        return int(io.InvalidInput), ""
    }
    own<io.Buf> = io.NewBuf(n_i)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), n_i)
    rfut<ioutil.Read> = tcp_read_leaf(bits, rb)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok {
        return int(rerr), ""
    }
    return 0, buf_to_dyn_string(own, rn)
}

// Read and discard up to max_n bytes (no dyn string alloc). Returns err (0=ok).
async drain(st, max_n) {
    bits<u64> = st.raw
    n_i<i32> = dyn_i32(max_n)
    if n_i <= 0 {
        return int(io.InvalidInput), 0
    }
    own<io.Buf> = io.NewBuf(n_i)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), n_i)
    rfut<ioutil.Read> = tcp_read_leaf(bits, rb)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok {
        return int(rerr), 0
    }
    return 0, int(rn.(i32))
}

func closeStream(st) {
    if st == null {
        return
    }
    bits<u64> = st.raw
    tcp_close_leaf(bits)
    st.raw = 0
}
