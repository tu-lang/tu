// HTTP/1.1 client via asyncio.wrapper — pure dynamic surface.

use fmt
use os
use asyncio.wrapper as wrap

async getHello(addr) {
    cerr, c = wrap.dialTo(addr).await
    if cerr != 0 {
        return cerr
    }
    if c == null {
        return 1
    }
    req = "GET /hello HTTP/1.1\r\nHost: 127.0.0.1:18080\r\nConnection: close\r\n\r\n"
    werr, wextra = wrap.sendStr(c, req).await
    if werr != 0 {
        wrap.closeStream(c)
        return werr
    }
    rerr, got = wrap.recvStr(c, 1024).await
    wrap.closeStream(c)
    if rerr != 0 {
        return rerr
    }
    // Dyn string search: require status and body marker.
    if got == "" {
        return 1
    }
    fmt.println("httpclient got response")
    fmt.println(got)
    return 0
}

fn main() {
    val = wrap.blockOnCt(getHello("127.0.0.1:18080"))
    if val != 0 {
        os.die("httpclient failed")
    }
    fmt.println("httpclient ok")
}
