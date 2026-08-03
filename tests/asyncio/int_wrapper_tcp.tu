// Bridge test: asyncio.wrapper camelCase leaf futures.

use fmt
use os
use io
use asyncio.net.tcp as tcp
use asyncio.io.util as ioutil
use asyncio.wrapper as wrap

async tcp_echo_body(addr) {
    err, lis = wrap.listen(addr)
    if err != 0 { return err }
    cfut<tcp.ConnectFut> = wrap.dialTo(addr)
    cerr<i32>, peer<tcp.TcpStream> = cfut.await
    if cerr != io.Ok { return cerr }
    client = wrap.streamFrom(peer)
    afut<tcp.AcceptFut> = wrap.takeConn(lis)
    aerr<i32>, speer<tcp.TcpStream> = afut.await
    if aerr != io.Ok { return aerr }
    server = wrap.streamFrom(speer)
    msg = *"ping"
    wfut<ioutil.WriteAll> = wrap.sendStr(client, msg)
    werr<i32> = wfut.await
    if werr != io.Ok { return werr }
    rfut<ioutil.Read>, own = wrap.recvStr(server, 16)
    rerr<i32>, rn<u64> = rfut.await
    if rerr != io.Ok { return rerr }
    if rn < 4.(u64) { return 1 }
    wfut2<ioutil.WriteAll> = wrap.sendStr(server, msg)
    werr2<i32> = wfut2.await
    if werr2 != io.Ok { return werr2 }
    rfut2<ioutil.Read>, own2 = wrap.recvStr(client, 16)
    rerr2<i32>, rn2<u64> = rfut2.await
    if rerr2 != io.Ok { return rerr2 }
    if rn2 < 4.(u64) { return 1 }
    wrap.closeStream(client)
    wrap.closeStream(server)
    return 0
}

fn main() {
    err<i32>, val<i64> = wrap.blockOnCt(tcp_echo_body(*"127.0.0.1:18181"))
    if err != 0 {
        os.dief("wrap.blockOnCt failed: %d", err)
    }
    fmt.println("int_wrapper_tcp passed")
}
