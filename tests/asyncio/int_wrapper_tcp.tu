// Bridge test: asyncio.wrapper camelCase dyn API (no typed Mem futures).

use fmt
use os
use asyncio.wrapper as wrap

async tcpEchoBody(addr) {
    err, lis = wrap.listen(addr)
    if err != 0 {
        return err
    }
    cerr, client = wrap.dialTo(addr).await
    if cerr != 0 {
        return cerr
    }
    if client == null {
        return 1
    }
    aerr, server = wrap.takeConn(lis).await
    if aerr != 0 {
        return aerr
    }
    if server == null {
        return 1
    }
    werr, wextra = wrap.sendStr(client, "ping").await
    if werr != 0 {
        return werr
    }
    rerr, got = wrap.recvStr(server, 16).await
    if rerr != 0 {
        return rerr
    }
    if got != "ping" {
        return 1
    }
    werr2, wextra2 = wrap.sendStr(server, "ping").await
    if werr2 != 0 {
        return werr2
    }
    rerr2, got2 = wrap.recvStr(client, 16).await
    if rerr2 != 0 {
        return rerr2
    }
    if got2 != "ping" {
        return 1
    }
    wrap.closeStream(client)
    wrap.closeStream(server)
    return 0
}

fn main() {
    val = wrap.blockOnCt(tcpEchoBody("127.0.0.1:18181"))
    if val != 0 {
        os.die("wrap.blockOnCt failed")
    }
    fmt.println("int_wrapper_tcp passed")
}
