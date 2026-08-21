// HTTP/1.1 client via asyncio.wrapper — pure dynamic OOP surface.

use fmt
use os
use asyncio.wrapper as asyncio

async getHello(addr) {
    cerr, c = asyncio.dialTo(addr).await
    if cerr != 0 {
        return cerr
    }
    if c == null {
        return 1
    }
    req = "GET /hello HTTP/1.1\r\nHost: 127.0.0.1:18080\r\nConnection: close\r\n\r\n"
    werr, wextra = c.sendStr(req).await
    if werr != 0 {
        c.close()
        return werr
    }
    rerr, got = c.recvStr(1024).await
    c.close()
    if rerr != 0 {
        return rerr
    }
    if got == "" {
        return 1
    }
    fmt.println("httpclient got response")
    fmt.println(got)
    return 0
}

fn main() {
    val = asyncio.blockOnCt(getHello("127.0.0.1:18080"))
    if val != 0 {
        os.die("httpclient failed")
    }
    fmt.println("httpclient ok")
}
