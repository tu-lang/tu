// Persistent HTTP/1.1 server for load testing (not a formal http package).
// Pure dynamic OOP demo over the asyncio / asyncio.net.tcp export facades —
// multi_thread + per-conn go.

use fmt
use os
use asyncio
use asyncio.net.tcp

okResp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\nConnection: close\r\n\r\nHello, world!"

async serveOne(st) {
    derr, n = st.drain(4096).await
    if derr != 0 {
        st.close()
        return 0
    }
    werr, wextra = st.sendStr(okResp).await
    st.close()
    return 0
}

class HttpServer {
    func init() {
    }
}

async HttpServer::run() {
    addr = "127.0.0.1:18080"
    err, lis = tcp.listen(addr)
    if err != 0 {
        return err
    }
    fmt.println("httpserver listening on http://127.0.0.1:18080 (MT spawn)")
    loop {
        aerr, st = lis.takeConn().await
        if aerr != 0 {
            continue
        }
        if st == null {
            continue
        }
        asyncio.go(serveOne(st))
    }
}

fn main() {
    server = new HttpServer()
    val = asyncio.blockOnMt(10, server.run())
    if val != 0 {
        fmt.println("httpserver listen failed")
        fmt.println(val)
        os.die("httpserver stopped")
    }
}
