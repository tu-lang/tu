// Persistent HTTP/1.1 server for load testing (not a formal http package).
// Engine multi_thread + per-conn spawn (ab/wrk). Sequential CT path is kept
// as a comment below for debugging fairness regressions.

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

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

// Cached once — avoid per-request string.S/NewBuf GC pressure under ab.
g_ok_resp<io.Buf> = null
g_ok_ready<i32> = 0

fn fixed_ok_response() io.Buf {
    if g_ok_ready == 1 {
        return g_ok_resp
    }
    resp<string.String> = string.S(*"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\nConnection: close\r\n\r\nHello, world!")
    g_ok_resp = str_buf(resp)
    g_ok_ready = 1
    return g_ok_resp
}

fn close_peer(peer<tcp.TcpStream>) {
    if peer != null && peer.poll_ev != null {
        peer.poll_ev.close()
    }
}

async serve_one(peer<tcp.TcpStream>) {
    own<io.Buf> = io.NewBuf(4096)
    rb<aio.ReadBuf> = aio.read_buf_from_i8(own.ptr(), 4096)
    rfut<ioutil.Read> = ioutil.read(peer, rb)
    rerr<i32>, rn<u64> = rfut.await
    if rerr == io.Ok && rn > 0.(u64) {
        wbuf<io.Buf> = fixed_ok_response()
        w<aio.AsyncWrite> = peer
        wfut<ioutil.WriteAll> = ioutil.write_all(w, wbuf)
        wfut.await
    }
    close_peer(peer)
    return io.Ok
}

fn serve_one_fut(peer<tcp.TcpStream>) runtime.Future {
    return serve_one(peer)
}

mem HttpServer {
    u64 pad
}

async HttpServer::run() {
    addr_s<string.String> = string.S(*"127.0.0.1:18080")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok {
        return perr
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok {
        return berr
    }
    err<i32>, h<rt.Handle> = rt.Handle::current()
    if err != 0 {
        return err
    }
    // Touch cache before accept loop.
    fixed_ok_response()
    fmt.println("httpserver listening on http://127.0.0.1:18080 (MT spawn)")

    loop {
        afut<tcp.AcceptFut> = listener.accept()
        aerr<i32>, peer<tcp.TcpStream> = afut.await
        if aerr != io.Ok {
            continue
        }
        h.spawn(serve_one_fut(peer))
    }
}

fn main() {
    job<HttpServer> = new HttpServer {
        pad: 0
    }
    body_f<runtime.Future> = job.run()
    b<rt.Builder> = rt.Builder::new_multi_thread()
    b = b.worker_threads(4)
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, body_f, 0)
    // Native i32 must go through int() for dyn varargs (printf/dief); bare
    // i32 slots SEGV inside dynstringfmt.
    if err != 0 {
        os.dief("block_on failed: %d", int(err))
    }
    ri<i32> = val
    if ri != io.Ok {
        if ri == io.AddrInUse {
            os.dief("httpserver bind failed: address already in use (127.0.0.1:18080)")
        }
        os.dief("httpserver stopped: %d", int(ri))
    }
}
