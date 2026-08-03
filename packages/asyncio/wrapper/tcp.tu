// Package factories + engine leaf bridges for asyncio.wrapper.
// Stream/Listener OOP methods that await Mem live in shell.tu.

use io
use std
use string
use net
use asyncio.util
use asyncio.net.tcp as tcp
use asyncio.io as aio
use asyncio.io.util as ioutil

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
        return int(perr), null
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(sa)
    if berr != io.Ok {
        return int(berr), null
    }
    out = listenerFrom(listener)
    return 0, out
}

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
    st = streamFrom(peer)
    return 0, st
}

func streamClose(st) {
    if st == null {
        return
    }
    bits<u64> = st.raw
    tcp_close_leaf(bits)
    st.raw = 0
}
