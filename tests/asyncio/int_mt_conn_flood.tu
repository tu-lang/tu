// MT connection flood: accept + fire-and-forget spawn (JoinHandle::detach).
// Locks the httpserver pattern — Tu has no Drop; discarding handles without
// detach leaks JOIN_INTEREST and wedges long-lived servers under load.

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

async echo_detach(peer<tcp.TcpStream>) {
    own<io.Buf> = io.NewBuf(64)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), 64)
    rerr<i32>, rn<u64> = ioutil.read(peer, rb).await
    if rerr != io.Ok {
        close_peer(peer)
        return rerr.(i64)
    }
    if rn == 0.(u64) {
        close_peer(peer)
        return io.Ok.(i64)
    }
    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp<i8*> = own.ptr()
    std.memcpy(ep, sp, rn)
    w<aio.AsyncWrite> = peer
    werr<i32> = ioutil.write_all(w, echo).await
    close_peer(peer)
    if werr != io.Ok {
        return werr.(i64)
    }
    return io.Ok.(i64)
}

fn echo_detach_fut(peer<tcp.TcpStream>) runtime.Future {
    return echo_detach(peer)
}

async client_one(addr<net.SocketAddr>, msg_s<string.String>) {
    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok {
        return cerr.(i64)
    }
    wbuf<io.Buf> = str_buf(msg_s)
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
    mlen<i32> = std.strlen(msg_s.str())
    if rn != mlen.(u64) {
        return io.OtherParse.(i64)
    }
    return io.Ok.(i64)
}

fn client_one_fut(addr<net.SocketAddr>, msg_s<string.String>) runtime.Future {
    return client_one(addr, msg_s)
}

async flood_round(port_base<i32>, conns<i32>) {
    addr_s<string.String> = string.S(*"127.0.0.1:34700")
    if port_base == 1 { addr_s = string.S(*"127.0.0.1:34701") }
    if port_base == 2 { addr_s = string.S(*"127.0.0.1:34702") }
    if port_base == 3 { addr_s = string.S(*"127.0.0.1:34703") }
    if port_base == 4 { addr_s = string.S(*"127.0.0.1:34704") }
    if port_base == 5 { addr_s = string.S(*"127.0.0.1:34705") }
    if port_base == 6 { addr_s = string.S(*"127.0.0.1:34706") }
    if port_base == 7 { addr_s = string.S(*"127.0.0.1:34707") }
    if port_base == 8 { addr_s = string.S(*"127.0.0.1:34708") }
    if port_base == 9 { addr_s = string.S(*"127.0.0.1:34709") }
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
    msg<string.String> = string.S(*"flood")
    done<i32> = 0
    while done < conns {
        cjh<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
        aerr<i32>, peer<tcp.TcpStream> = listener.accept().await
        if aerr != io.Ok {
            return aerr.(i64)
        }
        sjh<task.JoinHandle> = h.spawn(echo_detach_fut(peer))
        // httpserver path: drop server JoinHandle without await.
        sjh.detach()
        cerr2<i32> = cjh.await.(i32)
        if cerr2 != io.Ok {
            return io.OtherParse.(i64)
        }
        done += 1
    }
    hold<i32> = atime.sleep(atime.from_millis(30)).await
    if hold != io.Ok {
        return hold.(i64)
    }
    return io.Ok.(i64)
}

fn flood_once(port_base<i32>, conns<i32>) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, flood_round(port_base, conns), 0)
    check(err == 0, "mt_conn_flood block_on failed")
    check(val.(i32) == io.Ok, "mt_conn_flood round failed")
}

fn main() {
    fmt.println("int_mt_conn_flood test")
    // Same-process multi-round: detach leak would wedge later rounds.
    r<i32> = 0
    while r < 10 {
        flood_once(r, 64)
        r += 1
    }
    fmt.println("int_mt_conn_flood passed")
}
