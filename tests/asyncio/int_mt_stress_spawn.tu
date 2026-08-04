// MT TCP spawn stress: waves of concurrent connect/accept/echo/close.
// Guards lost-wakeup under multi_thread (ab-style load in-process).

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

async echo_one(peer<tcp.TcpStream>) {
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

fn echo_one_fut(peer<tcp.TcpStream>) runtime.Future {
    return echo_one(peer)
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

async mt_stress_spawn_wave(port_off<i32>) {
    // Unique port per wave avoids TIME_WAIT collisions across sequential runtimes.
    addr_s<string.String> = string.S(*"127.0.0.1:34670")
    if port_off == 1 { addr_s = string.S(*"127.0.0.1:34671") }
    if port_off == 2 { addr_s = string.S(*"127.0.0.1:34672") }
    if port_off == 3 { addr_s = string.S(*"127.0.0.1:34673") }
    if port_off == 4 { addr_s = string.S(*"127.0.0.1:34674") }
    if port_off == 5 { addr_s = string.S(*"127.0.0.1:34675") }
    if port_off == 6 { addr_s = string.S(*"127.0.0.1:34676") }
    if port_off == 7 { addr_s = string.S(*"127.0.0.1:34677") }
    if port_off == 8 { addr_s = string.S(*"127.0.0.1:34678") }
    if port_off == 9 { addr_s = string.S(*"127.0.0.1:34679") }
    if port_off == 10 { addr_s = string.S(*"127.0.0.1:34680") }
    if port_off == 11 { addr_s = string.S(*"127.0.0.1:34681") }
    if port_off == 12 { addr_s = string.S(*"127.0.0.1:34682") }
    if port_off == 13 { addr_s = string.S(*"127.0.0.1:34683") }
    if port_off == 14 { addr_s = string.S(*"127.0.0.1:34684") }
    if port_off == 15 { addr_s = string.S(*"127.0.0.1:34685") }
    if port_off == 16 { addr_s = string.S(*"127.0.0.1:34686") }
    if port_off == 17 { addr_s = string.S(*"127.0.0.1:34687") }
    if port_off == 18 { addr_s = string.S(*"127.0.0.1:34688") }
    if port_off == 19 { addr_s = string.S(*"127.0.0.1:34689") }
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

    msg<string.String> = string.S(*"ping")
    // Eight concurrent client+server pairs per wave.
    c0<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c1<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c2<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c3<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c4<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c5<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c6<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))
    c7<task.JoinHandle> = h.spawn(client_one_fut(addr, msg))

    a0_err<i32>, p0<tcp.TcpStream> = listener.accept().await
    if a0_err != io.Ok { return a0_err.(i64) }
    s0<task.JoinHandle> = h.spawn(echo_one_fut(p0))
    a1_err<i32>, p1<tcp.TcpStream> = listener.accept().await
    if a1_err != io.Ok { return a1_err.(i64) }
    s1<task.JoinHandle> = h.spawn(echo_one_fut(p1))
    a2_err<i32>, p2<tcp.TcpStream> = listener.accept().await
    if a2_err != io.Ok { return a2_err.(i64) }
    s2<task.JoinHandle> = h.spawn(echo_one_fut(p2))
    a3_err<i32>, p3<tcp.TcpStream> = listener.accept().await
    if a3_err != io.Ok { return a3_err.(i64) }
    s3<task.JoinHandle> = h.spawn(echo_one_fut(p3))
    a4_err<i32>, p4<tcp.TcpStream> = listener.accept().await
    if a4_err != io.Ok { return a4_err.(i64) }
    s4<task.JoinHandle> = h.spawn(echo_one_fut(p4))
    a5_err<i32>, p5<tcp.TcpStream> = listener.accept().await
    if a5_err != io.Ok { return a5_err.(i64) }
    s5<task.JoinHandle> = h.spawn(echo_one_fut(p5))
    a6_err<i32>, p6<tcp.TcpStream> = listener.accept().await
    if a6_err != io.Ok { return a6_err.(i64) }
    s6<task.JoinHandle> = h.spawn(echo_one_fut(p6))
    a7_err<i32>, p7<tcp.TcpStream> = listener.accept().await
    if a7_err != io.Ok { return a7_err.(i64) }
    s7<task.JoinHandle> = h.spawn(echo_one_fut(p7))

    // Join all servers then clients.
    if s0.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s1.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s2.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s3.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s4.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s5.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s6.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if s7.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c0.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c1.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c2.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c3.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c4.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c5.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c6.await.(i32) != io.Ok { return io.OtherParse.(i64) }
    if c7.await.(i32) != io.Ok { return io.OtherParse.(i64) }

    hold<i32> = atime.sleep(atime.from_millis(20)).await
    if hold != io.Ok {
        return hold.(i64)
    }
    return io.Ok.(i64)
}

fn int_mt_stress_spawn_once(port_off<i32>) {
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_stress_spawn_wave(port_off), 0)
    check(err == 0, "mt_stress_spawn block_on failed")
    check(val.(i32) == io.Ok, "mt_stress_spawn wave failed")
}

fn main() {
    fmt.println("int_mt_stress_spawn test")
    n<i32> = 0
    while n < 20 {
        int_mt_stress_spawn_once(n)
        n += 1
    }
    fmt.println("int_mt_stress_spawn passed")
}
