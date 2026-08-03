// Persistent HTTP/1.1 server for load testing (not a formal http package).
// Pure dynamic demo: asyncio.wrapper camelCase only — no mem, no type
// asserts, no engine TCP/runtime types, no native cstrings.
//
// Uses blockOnCt + sequential accept→serve. MT + wrap.spawn under dyn
// alloc currently hits malloc deadlock (see co/docs/optimize).

use fmt
use os
use asyncio.wrapper as wrap

okResp = "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 13\r\nConnection: close\r\n\r\nHello, world!"

async serveOne(st) {
    // Drain request without building a dyn string (avoids string.new GC pressure).
    derr, n = wrap.drain(st, 4096).await
    if derr != 0 {
        wrap.closeStream(st)
        return 0
    }
    werr, wextra = wrap.sendStr(st, okResp).await
    wrap.closeStream(st)
    return 0
}

class HttpServer {
    func init() {
    }
}

async HttpServer::run() {
    addr = "127.0.0.1:18080"
    err, lis = wrap.listen(addr)
    if err != 0 {
        return err
    }
    fmt.println("httpserver listening on http://127.0.0.1:18080 (CT sequential)")
    loop {
        aerr, st = wrap.takeConn(lis).await
        if aerr != 0 {
            continue
        }
        if st == null {
            continue
        }
        serveOne(st).await
    }
}

fn main() {
    server = new HttpServer()
    val = wrap.blockOnCt(server.run())
    if val != 0 {
        os.die("httpserver stopped")
    }
}
