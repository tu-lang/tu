// MT enable_all: TCP IO interleaved with sleep/spawn (foundation stress).
// Ports 34569 (smoke) and 34570..34573 (shutdown cycles).

use fmt
use os
use io
use string
use std
use net
use runtime
use asyncio.task
use asyncio.runtime as rt
use asyncio.net as anet
use asyncio.net.tcp as tcp
use asyncio.time as atime
use asyncio.io as aio
use asyncio.io.util as ioutil
use asyncio.util

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

fn cmp_buf_eq(got<io.Buf>, want_s<string.String>, nbytes<u64>) i32 {
    src<u8*> = want_s.str()
    gp<i8*> = got.ptr()
    g<u8*> = null
    g = gp
    i<u64> = 0
    while i < nbytes {
        if g[i] != src[i] return io.OtherParse
        i += 1
    }
    return io.Ok
}

mem UnitOkFut: async {
    i64 _pad
}
UnitOkFut::poll(ctx) {
    return runtime.PollReady, 1.(i64)
}

fn unit_ok_fut() runtime.Future {
    f<UnitOkFut> = new UnitOkFut{}
    fut<runtime.Future> = f
    return fut
}

// 0 = smoke 34569; 1..4 = cycle ports 34570..34573.
g_iot_port_sel<i32> = 0

fn iot_addr_string() string.String {
    if g_iot_port_sel == 0 return string.S(*"127.0.0.1:34569")
    if g_iot_port_sel == 1 return string.S(*"127.0.0.1:34570")
    if g_iot_port_sel == 2 return string.S(*"127.0.0.1:34571")
    if g_iot_port_sel == 3 return string.S(*"127.0.0.1:34572")
    return string.S(*"127.0.0.1:34573")
}

// Sleep, TCP echo, sleep, spawn burst under one MT runtime.
async mt_io_timer_body() {
    e0<i32> = atime.sleep(atime.from_millis(5)).await
    if e0 != io.Ok return e0.(i64)

    addr_s<string.String> = iot_addr_string()
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok return perr.(i64)

    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok return berr.(i64)

    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok return cerr.(i64)

    aerr<i32>, server<tcp.TcpStream> = listener.accept().await
    if aerr != io.Ok return aerr.(i64)

    msg<string.String> = string.S(*"mix")
    mlen<i32> = std.strlen(msg.str())
    mlen_u<u64> = mlen.(u64)
    wbuf<io.Buf> = str_buf(msg)

    wclient<ioutil.AsyncWrite> = client
    werr<i32> = ioutil.write_all(wclient, wbuf).await
    if werr != io.Ok return werr.(i64)

    e1<i32> = atime.sleep(atime.from_millis(5)).await
    if e1 != io.Ok return e1.(i64)

    own1<io.Buf> = io.NewBuf(16)
    rb1<aio.ReadBuf> = aio.read_buf_from_i8(own1.ptr(), 16)
    rerr<i32>, rn<u64> = ioutil.read(server, rb1).await
    if rerr != io.Ok return rerr.(i64)
    if rn != mlen_u return io.OtherParse.(i64)
    cmp_err<i32> = cmp_buf_eq(own1, msg, rn)
    if cmp_err != io.Ok return cmp_err.(i64)

    echo<io.Buf> = io.NewBuf(rn.(i32))
    ep<i8*> = echo.ptr()
    sp1<i8*> = own1.ptr()
    std.memcpy(ep, sp1, rn)
    wserver<ioutil.AsyncWrite> = server
    werr2<i32> = ioutil.write_all(wserver, echo).await
    if werr2 != io.Ok return werr2.(i64)

    own2<io.Buf> = io.NewBuf(16)
    rb2<aio.ReadBuf> = aio.read_buf_from_i8(own2.ptr(), 16)
    rerr2<i32>, n2<u64> = ioutil.read(client, rb2).await
    if rerr2 != io.Ok return rerr2.(i64)
    if n2 != mlen_u return io.OtherParse.(i64)

    errh<i32>, h<rt.Handle> = rt.Handle::current()
    if errh != 0 return errh.(i64)
    j0<task.JoinHandle> = h.spawn(unit_ok_fut())
    j1<task.JoinHandle> = h.spawn(unit_ok_fut())
    j2<task.JoinHandle> = h.spawn(unit_ok_fut())
    j3<task.JoinHandle> = h.spawn(unit_ok_fut())
    sum<i64> = j0.await + j1.await + j2.await + j3.await
    if sum.(i32) != 4 return io.OtherParse.(i64)

    e2<i32> = atime.sleep(atime.from_millis(5)).await
    if e2 != io.Ok return e2.(i64)
    return io.Ok.(i64)
}

fn int_mt_io_timer() {
    fmt.println("int_mt_io_timer test")
    g_iot_port_sel = 0
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, mt_io_timer_body(), 0)
    check(err == 0, "io_timer block_on failed")
    check(val.(i32) == io.Ok, "io_timer body failed")
    fmt.println("int_mt_io_timer passed")
}

// Fresh port each MT create/shutdown cycle.
fn int_mt_io_timer_cycles() {
    fmt.println("int_mt_io_timer_cycles test")
    n<i32> = 0
    while n < 4 {
        g_iot_port_sel = n + 1
        b<rt.Builder> = rt.Builder::new_multi_thread()
        b = b.worker_threads(4)
        b = b.enable_all()
        err<i32>, val<i64> = rt.builder_block_on(b, mt_io_timer_body(), 0)
        if err != 0 {
            fmt.println("io_timer cycle block_on failed")
            os.exit(1)
        }
        if val.(i32) != io.Ok {
            fmt.println("io_timer cycle body failed")
            os.exit(1)
        }
        n += 1
    }
    fmt.println("int_mt_io_timer_cycles passed")
}

fn main() {
    int_mt_io_timer()
    int_mt_io_timer_cycles()
}
