// event.Source api enroll: TcpListener (single api) + TcpStream (Read+Write+Source).
use fmt
use os
use io
use string
use std
use net
use netio
use netio.event
use netio.net.tcp
use asyncio.util

fn main() {
    addr_s<string.String> = string.S(*"127.0.0.1:34569")
    slen<i32> = std.strlen(addr_s.str())
    perr<i32>, addr<net.SocketAddr> = util.net_parse_ascii_bytes(addr_s.str(), slen)
    if perr != io.Ok {
        os.dief("parse %d", perr)
    }

    berr<i32> = tcp.TcpListener::bind(addr)
    if berr != io.Ok {
        os.dief("bind %d", berr)
    }
    l<tcp.TcpListener> = tcp.tcp_listener_last()

    perr2<i32>, p<netio.Poll> = netio.Poll::new(0)
    if perr2 != io.Ok {
        os.dief("poll %d", perr2)
    }
    reg<netio.Registry> = p.registry()
    t<netio.Token> = netio.token_from_u64(1.(u64))
    interests<netio.Interest> = netio.readable_interest()

    src_l<event.Source> = l
    e1<i32> = src_l.enroll(reg, t, interests)
    if e1 != io.Ok {
        os.dief("listener Source.enroll %d", e1)
    }

    // Multi-api TcpStream: coerce to Source then enroll (must not SEGV)
    cerr<i32>, cbits<u64> = tcp.TcpStream::connect(addr)
    if cerr != io.Ok {
        os.dief("connect %d", cerr)
    }
    aerr<i32>, sbits<u64>, abits<u64> = l.accept()
    if aerr != io.Ok {
        os.dief("accept %d", aerr)
    }
    if sbits == 0.(u64) {
        os.dief("accept null stream")
    }
    stream<tcp.TcpStream> = null
    stream = sbits
    src_s<event.Source> = stream
    t2<netio.Token> = netio.token_from_u64(2.(u64))
    e2<i32> = src_s.enroll(reg, t2, interests)
    if e2 != io.Ok {
        os.dief("stream Source.enroll %d", e2)
    }
    fmt.println("int_source_enroll done")
}
