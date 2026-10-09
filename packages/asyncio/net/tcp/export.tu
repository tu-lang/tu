// Dynamic facade of asyncio.net.tcp: Listener / Stream class shells with
// camelCase methods plus listen / dialTo factories; dyn inputs and outputs.
// Class methods are dyn defs in a static package — static syntax needs unsafe.

use io
use std
use string
use net
use asyncio.util
use asyncio.io as aio
use asyncio.io.util as ioutil

// Dynamic listener shell; raw holds the TcpListener.
class Listener {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
}

// Dynamic stream shell; raw holds the TcpStream (0 after close).
class Stream {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
    func close() {
        streamClose(this)
    }
}

// Wrap an engine TcpListener in a Listener shell.
export func listenerFrom(engine_obj) {
    lis = new Listener(0)
    lis.raw = engine_obj
    return lis
}

// Wrap an engine TcpStream in a Stream shell.
export func streamFrom(engine_obj) {
    st = new Stream(0)
    st.raw = engine_obj
    return st
}

// Dyn addr string -> SocketAddr.
unsafe fn dyn_parse_addr(addr) (i32, net.SocketAddr) {
    addr_s<string.String> = util.dyn_string(addr)
    slen<i32> = std.strlen(addr_s.str())
    // Cross-pkg (i32, Mem) drops SocketAddr fields on Windows PE; take bits.
    perr<i32>, bits<u64> = util.net_parse_ascii_bytes_bits(addr_s.str(), slen)
    if perr != io.Ok {
        empty<net.SocketAddr> = null
        return perr, empty
    }
    sa<net.SocketAddr> = util.net_socket_addr_from_bits(bits)
    return perr, sa
}

// Leaf futures built from the raw slots, awaited by the class methods.
fn dyn_accept_leaf(bits<u64>) AcceptFut {
    l<TcpListener> = bits.(TcpListener)
    return l.accept()
}

fn dyn_connect_leaf(addr<net.SocketAddr>) ConnectFut {
    return TcpStream::connect(addr)
}

fn dyn_write_leaf(bits<u64>, buf<io.Buf>) ioutil.WriteAll {
    st<TcpStream> = bits.(TcpStream)
    w<aio.AsyncWrite> = st
    return ioutil.write_all(w, buf)
}

fn dyn_read_leaf(bits<u64>, rb<aio.ReadBuf>) ioutil.Read {
    st<TcpStream> = bits.(TcpStream)
    return ioutil.read(st, rb)
}

// Closes the stream's poll source; no-op on a zero slot.
fn dyn_close_leaf(bits<u64>) {
    if bits == 0 {
        return
    }
    st<TcpStream> = bits.(TcpStream)
    if st.poll_ev != null {
        st.poll_ev.close()
    }
}

// Bind a listener on addr ("ip:port"). Returns (err, Listener or null).
export func listen(addr) {
    perr<i32>, sa<net.SocketAddr> = dyn_parse_addr(addr)
    if perr != io.Ok {
        return int(perr), null
    }
    berr<i32>, listener<TcpListener> = TcpListener::bind(sa)
    if berr != io.Ok {
        return int(berr), null
    }
    out = listenerFrom(listener)
    return 0, out
}

// Connect to addr ("ip:port"). Resolves to (err, Stream or null).
export async dialTo(addr) {
    perr<i32>, sa<net.SocketAddr> = dyn_parse_addr(addr)
    if perr != io.Ok {
        return int(perr), null
    }
    cfut<ConnectFut> = dyn_connect_leaf(sa)
    cerr<i32>, peer<TcpStream> = cfut.await
    if cerr != io.Ok {
        return int(cerr), null
    }
    if peer == null {
        return int(io.Other), null
    }
    st = streamFrom(peer)
    return 0, st
}

// Close st and clear its raw slot; null-safe and idempotent.
export func streamClose(st) {
    if st == null {
        return
    }
    bits<u64> = st.raw
    dyn_close_leaf(bits)
    st.raw = 0
}

// Accept one connection. Resolves to (err, Stream or null).
unsafe async Listener::takeConn() {
    bits<u64> = this.raw
    afut<AcceptFut> = dyn_accept_leaf(bits)
    aerr<i32>, peer<TcpStream> = afut.await
    if aerr != io.Ok {
        return int(aerr), null
    }
    if peer == null {
        return int(io.Other), null
    }
    st = streamFrom(peer)
    return 0, st
}

// Write all bytes of dynamic string s. Resolves to (err, "").
unsafe async Stream::sendStr(s) {
    bits<u64> = this.raw
    buf<io.Buf> = util.dyn_buf(s)
    wfut<ioutil.WriteAll> = dyn_write_leaf(bits, buf)
    werr<i32> = wfut.await
    if werr != io.Ok {
        return int(werr), ""
    }
    return 0, ""
}

// Read up to max_n bytes. Resolves to (err, dynamic string).
unsafe async Stream::recvStr(max_n) {
    bits<u64> = this.raw
    n_i<i32> = util.dyn_i32(max_n)
    if n_i <= 0 {
        return int(io.InvalidInput), ""
    }
    own<io.Buf> = io.NewBuf(n_i)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), n_i)
    rfut<ioutil.Read> = dyn_read_leaf(bits, rb)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok {
        return int(rerr), ""
    }
    return 0, util.buf_to_dyn_string(own, rn)
}

// Read up to max_n bytes and discard them. Resolves to (err, byte count).
unsafe async Stream::drain(max_n) {
    bits<u64> = this.raw
    n_i<i32> = util.dyn_i32(max_n)
    if n_i <= 0 {
        return int(io.InvalidInput), 0
    }
    own<io.Buf> = io.NewBuf(n_i)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), n_i)
    rfut<ioutil.Read> = dyn_read_leaf(bits, rb)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok {
        return int(rerr), 0
    }
    return 0, int(rn.(i32))
}
