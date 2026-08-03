// CT fairness: hot accept root must yield so per-conn spawn tasks run.
// Without coop budget / event_interval, serve tasks starve under ready accept.

use fmt
use os
use io
use string
use std
use net
use runtime
use asyncio.runtime as rt
use asyncio.net.tcp as tcp
use asyncio.io as aio
use asyncio.io.util as ioutil
use asyncio.util
use asyncio.task
use asyncio.time as atime

fn check(ok<i32>, msg) {
    if ok != 0 return
    fmt.println(msg)
    os.exit(1)
}

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

fn close_peer(peer<tcp.TcpStream>) {
    if peer != null && peer.poll_ev != null {
        peer.poll_ev.close()
    }
}

async serve_one(peer<tcp.TcpStream>) {
    own<io.Buf> = io.NewBuf(64)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), 64)
    rerr<i32>, rn<u64> = ioutil.read(peer, rb).await
    if rerr == io.Ok && rn > 0.(u64) {
        echo<io.Buf> = io.NewBuf(rn.(i32))
        ep<i8*> = echo.ptr()
        sp<i8*> = own.ptr()
        std.memcpy(ep, sp, rn)
        w<aio.AsyncWrite> = peer
        ioutil.write_all(w, echo).await
    }
    close_peer(peer)
    return io.Ok.(i64)
}

fn serve_one_fut(peer<tcp.TcpStream>) runtime.Future {
    return serve_one(peer)
}

async client_one(addr<net.SocketAddr>) {
    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok {
        return cerr.(i64)
    }
    msg<string.String> = string.S(*"x")
    wbuf<io.Buf> = str_buf(msg)
    wc<aio.AsyncWrite> = client
    werr<i32> = ioutil.write_all(wc, wbuf).await
    if werr != io.Ok {
        close_peer(client)
        return werr.(i64)
    }
    own<io.Buf> = io.NewBuf(64)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), 64)
    rerr<i32>, rn<u64> = ioutil.read(client, rb).await
    close_peer(client)
    if rerr != io.Ok {
        return rerr.(i64)
    }
    if rn != 1.(u64) {
        return io.OtherParse.(i64)
    }
    return io.Ok.(i64)
}

fn client_one_fut(addr<net.SocketAddr>) runtime.Future {
    return client_one(addr)
}

// Root: accept N conns and spawn serve; join clients then servers.
async ct_spawn_fair_body() {
    addr_s<string.String> = string.S(*"127.0.0.1:34671")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok {
        return perr.(i64)
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok {
        return berr.(i64)
    }
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err.(i64)
    }

    // Start clients first so accept stays hot when the root loops.
    c0<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c1<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c2<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c3<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c4<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c5<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c6<task.JoinHandle> = h.spawn(client_one_fut(addr))
    c7<task.JoinHandle> = h.spawn(client_one_fut(addr))

    n<i32> = 0
    s0<task.JoinHandle> = null
    s1<task.JoinHandle> = null
    s2<task.JoinHandle> = null
    s3<task.JoinHandle> = null
    s4<task.JoinHandle> = null
    s5<task.JoinHandle> = null
    s6<task.JoinHandle> = null
    s7<task.JoinHandle> = null
    while n < 8 {
        aerr<i32>, peer<tcp.TcpStream> = listener.accept().await
        if aerr != io.Ok {
            return aerr.(i64)
        }
        jh<task.JoinHandle> = h.spawn(serve_one_fut(peer))
        if n == 0 { s0 = jh }
        if n == 1 { s1 = jh }
        if n == 2 { s2 = jh }
        if n == 3 { s3 = jh }
        if n == 4 { s4 = jh }
        if n == 5 { s5 = jh }
        if n == 6 { s6 = jh }
        if n == 7 { s7 = jh }
        n += 1
    }

    if c0.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c1.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c2.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c3.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c4.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c5.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c6.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c7.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s0.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s1.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s2.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s3.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s4.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s5.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s6.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s7.await.(i32) != io.Ok { return io.OtherParse.(i64) }

    hold<i32> = atime.sleep(atime.from_millis(10)).await
    if hold != io.Ok {
        return hold.(i64)
    }
    return io.Ok.(i64)
}

fn int_ct_spawn_fair_once() {
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, ct_spawn_fair_body(), 0)
    check(err == 0, "ct_spawn_fair block_on failed")
    check(val.(i32) == io.Ok, "ct_spawn_fair body failed")
}

fn main() {
    fmt.println("int_ct_spawn_fair test")
    n<i32> = 0
    while n < 10 {
        int_ct_spawn_fair_once()
        n += 1
    }
    fmt.println("int_ct_spawn_fair passed")
}
