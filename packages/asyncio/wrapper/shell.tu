// Listener / Stream dynamic shells + OOP camelCase methods.
// Member async await engine Mem via same-package leaf helpers (tcp.tu fns).
// Class methods are dyn defs in a static package — static syntax needs unsafe.

use io
use asyncio.net.tcp as tcp
use asyncio.io as aio
use asyncio.io.util as ioutil

class Listener {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
}

class Stream {
    raw = 0
    func init(bits) {
        this.raw = bits
    }
    func close() {
        streamClose(this)
    }
}

export func listenerFrom(engine_obj) {
    lis = new Listener(0)
    lis.raw = engine_obj
    return lis
}

export func streamFrom(engine_obj) {
    st = new Stream(0)
    st.raw = engine_obj
    return st
}

export func dial() {
    return new Stream(0)
}

unsafe async Listener::takeConn() {
    bits<u64> = this.raw
    afut<tcp.AcceptFut> = tcp_accept_leaf(bits)
    aerr<i32>, peer<tcp.TcpStream> = afut.await
    if aerr != io.Ok {
        return int(aerr), null
    }
    if peer == null {
        return int(io.Other), null
    }
    st = streamFrom(peer)
    return 0, st
}

unsafe async Stream::sendStr(s) {
    bits<u64> = this.raw
    buf<io.Buf> = dyn_buf(s)
    wfut<ioutil.WriteAll> = tcp_write_leaf(bits, buf)
    werr<i32> = wfut.await
    if werr != io.Ok {
        return int(werr), ""
    }
    return 0, ""
}

unsafe async Stream::recvStr(max_n) {
    bits<u64> = this.raw
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

unsafe async Stream::drain(max_n) {
    bits<u64> = this.raw
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
