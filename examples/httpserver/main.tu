// Persistent HTTP/1.1 server for load testing (not a formal http package).
// Pure dynamic OOP demo via asyncio.wrapper — multi_thread + per-conn spawn.

use fmt
use os
use asyncio.wrapper as asyncio

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
    err, lis = asyncio.listen(addr)
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
        asyncio.spawn(serveOne(st))
    }
}

fn main() {
    server = new HttpServer()
    val = asyncio.blockOnMt(10, server.run())
    if val != 0 {
        os.die("httpserver stopped")
    }
}
