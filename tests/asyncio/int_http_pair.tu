// Temporary HTTP loopback over asyncio.net.tcp (not asyncio.wrapper HTTP).
// Formal http package is out of scope; this only exercises asyncio IO with
// inline request/response bytes.

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

fn str_buf(s<string.String>) io.Buf {
    slen<i32> = std.strlen(s.str())
    b<io.Buf> = io.NewBuf(slen)
    p<i8*> = b.ptr()
    std.memcpy(p, s.str(), slen.(u64))
    return b
}

fn buf_has(got<io.Buf>, nbytes<u64>, needle<string.String>) i32 {
    nlen<i32> = std.strlen(needle.str())
    if nlen.(u64) > nbytes {
        return io.OtherParse
    }
    gp0<i8*> = got.ptr()
    g<u8*> = null
    g = gp0
    np0<i8*> = needle.str()
    n<u8*> = null
    n = np0
    limit<u64> = nbytes - nlen.(u64) + 1.(u64)
    i<u64> = 0
    while i < limit {
        j<i32> = 0
        ok<i32> = 1
        while j < nlen {
            gi<u64> = i + j.(u64)
            if g[gi] != n[j] {
                ok = 0
                break
            }
            j += 1
        }
        if ok == 1 {
            return io.Ok
        }
        i += 1
    }
    return io.OtherParse
}

mem HttpPairJob {
    u64 pad
}

async HttpPairJob::run() {
    addr_s<string.String> = string.S(*"127.0.0.1:18314")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok {
        return perr
    }
    berr<i32>, listener<tcp.TcpListener> = tcp.TcpListener::bind(addr)
    if berr != io.Ok {
        return berr
    }
    cerr<i32>, client<tcp.TcpStream> = tcp.TcpStream::connect(addr).await
    if cerr != io.Ok {
        return cerr
    }
    aerr<i32>, server<tcp.TcpStream> = listener.accept().await
    if aerr != io.Ok {
        return aerr
    }

    req<string.String> = string.S(*"GET /hello HTTP/1.1\r\nHost: 127.0.0.1\r\nConnection: close\r\n\r\n")
    wbuf<io.Buf> = str_buf(req)
    wc<aio.AsyncWrite> = client
    werr<i32> = ioutil.write_all(wc, wbuf).await
    if werr != io.Ok {
        return werr
    }

    own1<io.Buf> = io.NewBuf(512)
    rb1<aio.ReadBuf> = aio.read_buf_from_i8(own1.ptr(), 512)
    rerr<i32>, rn<u64> = ioutil.read(server, rb1).await
    if rerr != io.Ok {
        return rerr
    }
    if buf_has(own1, rn, string.S(*"GET /hello")) != io.Ok {
        return io.OtherParse
    }

    resp<string.String> = string.S(*"HTTP/1.1 200 OK\r\nContent-Length: 5\r\nConnection: close\r\n\r\nhello")
    rbuf<io.Buf> = str_buf(resp)
    ws<aio.AsyncWrite> = server
    werr2<i32> = ioutil.write_all(ws, rbuf).await
    if werr2 != io.Ok {
        return werr2
    }

    own2<io.Buf> = io.NewBuf(512)
    rb2<aio.ReadBuf> = aio.read_buf_from_i8(own2.ptr(), 512)
    rerr2<i32>, n2<u64> = ioutil.read(client, rb2).await
    if rerr2 != io.Ok {
        return rerr2
    }
    if buf_has(own2, n2, string.S(*"200 OK")) != io.Ok {
        return io.OtherParse
    }
    if buf_has(own2, n2, string.S(*"hello")) != io.Ok {
        return io.OtherParse
    }
    return io.Ok
}

fn int_http_pair() {
    job<HttpPairJob> = new HttpPairJob { pad: 0 }
    body_f<runtime.Future> = job.run()
    b<rt.Builder> = rt.Builder::new_current_thread()
    b = b.enable_all()
    err<i32>, val<i64> = rt.builder_block_on(b, body_f, 0)
    if err != 0 {
        os.dief("block_on failed: %d", err)
    }
    ri<i32> = val
    if ri != io.Ok {
        os.dief("http pair failed: %d", ri)
    }
    fmt.println("int_http_pair passed")
}

fn main() {
    int_http_pair()
}
