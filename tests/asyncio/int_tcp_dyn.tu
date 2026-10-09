// Dynamic export facade over TCP: asyncio.net.tcp listen / dialTo factories,
// Listener / Stream class methods, driven by the root asyncio.blockOnCt.

use fmt
use os
use asyncio
use asyncio.net.tcp

async tcpEchoBody(addr) {
    err, lis = tcp.listen(addr)
    if err != 0 {
        return err
    }
    cerr, client = tcp.dialTo(addr).await
    if cerr != 0 {
        return cerr
    }
    if client == null {
        return 1
    }
    aerr, server = lis.takeConn().await
    if aerr != 0 {
        return aerr
    }
    if server == null {
        return 1
    }
    werr, wextra = client.sendStr("ping").await
    if werr != 0 {
        return werr
    }
    rerr, got = server.recvStr(16).await
    if rerr != 0 {
        return rerr
    }
    if got != "ping" {
        return 1
    }
    werr2, wextra2 = server.sendStr("ping").await
    if werr2 != 0 {
        return werr2
    }
    rerr2, got2 = client.recvStr(16).await
    if rerr2 != 0 {
        return rerr2
    }
    if got2 != "ping" {
        return 1
    }
    client.close()
    server.close()
    return 0
}

fn main() {
    val = asyncio.blockOnCt(tcpEchoBody("127.0.0.1:18181"))
    if val != 0 {
        os.die("asyncio.blockOnCt failed")
    }
    fmt.println("int_tcp_dyn passed")
}
