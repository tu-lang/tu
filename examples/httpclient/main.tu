// HTTP/1.1 client via asyncio.wrapper leaf futures.
// Avoid string.new / dyn string search — that path can malloc-deadlock under GC.

use fmt
use os
use io
use asyncio.net.tcp as tcp
use asyncio.io.util as ioutil
use asyncio.wrapper as wrap

// Return 1 if needle bytes appear in buf[0..n).
fn buf_has(buf<io.Buf>, n<u64>, needle<i8*>, nlen<i32>) i32 {
    if nlen <= 0 {
        return 1
    }
    hn<i32> = n.(i32)
    if nlen > hn {
        return 0
    }
    hp<i8*> = buf.ptr()
    limit<i32> = hn - nlen + 1
    i<i32> = 0
    while i < limit {
        j<i32> = 0
        ok<i32> = 1
        while j < nlen {
            off<i32> = i + j
            if hp[off] != needle[j] {
                ok = 0
                break
            }
            j += 1
        }
        if ok == 1 {
            return 1
        }
        i += 1
    }
    return 0
}

async getHello(addr) {
    cfut<tcp.ConnectFut> = wrap.dialTo(addr)
    cerr<i32>, peer<tcp.TcpStream> = cfut.await
    if cerr != io.Ok {
        return cerr
    }
    c = wrap.streamFrom(peer)
    req = *"GET /hello HTTP/1.1\r\nHost: 127.0.0.1:18080\r\nConnection: close\r\n\r\n"
    wfut<ioutil.WriteAll> = wrap.sendStr(c, req)
    werr<i32> = wfut.await
    if werr != io.Ok {
        return werr
    }
    rfut<ioutil.Read>, own = wrap.recvStr(c, 1024)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok {
        return rerr
    }
    if buf_has(own, rn, *"200 OK", 6) == 0 {
        return 1
    }
    if buf_has(own, rn, *"Hello", 5) == 0 {
        return 1
    }
    wrap.closeStream(c)
    fmt.println("httpclient got 200 Hello")
    return 0
}

fn main() {
    err<i32>, val<i64> = wrap.blockOnCt(getHello(*"127.0.0.1:18080"))
    if err != 0 {
        os.dief("blockOnCt failed: %d", err)
    }
    fmt.println("httpclient ok")
}
