use io
use std
use string
use sys

ADDR_V4_KIND<i32> = 4
ADDR_V6_KIND<i32> = 6

// tokio SocketAddr tagged union; V4/V6 payloads are SocketAddrV4 / SocketAddrV6.

mem SocketAddr {
    i32 kind
    u64 v4_raw
    u64 v6_raw
}

fn strto_socket_addrs(s<string.String>) i32, std.Array {
    v<std.Array> = std.NewArray()
    return io.OtherParse, v
}

fn socket_addr_from_v4(sa_v4<SocketAddrV4>) SocketAddr {
    return new SocketAddr { kind: ADDR_V4_KIND, v4_raw: sa_v4, v6_raw: 0 }
}

fn socket_addr_from_v6(sa_v6<SocketAddrV6>) SocketAddr {
    return new SocketAddr { kind: ADDR_V6_KIND, v4_raw: 0, v6_raw: sa_v6 }
}

fn socket_addr_is_v4(addr<SocketAddr>) i32 {
    return addr.kind == ADDR_V4_KIND
}

fn socket_addr_is_v6(addr<SocketAddr>) i32 {
    return addr.kind == ADDR_V6_KIND
}

fn socket_addr_v4_store(addr<SocketAddr>) SocketAddrV4 {
    return socket_addr_v4_from_raw(addr.v4_raw)
}

fn socket_addr_v6_store(addr<SocketAddr>) SocketAddrV6 {
    return socket_addr_v6_from_raw(addr.v6_raw)
}

fn socket_addr_get_port(addr<SocketAddr>) u16 {
    if socket_addr_is_v4(addr) {
        return socket_addr_v4_store(addr).port_num()
    }
    return socket_addr_v6_store(addr).port_num()
}

fn socket_addr_assign_port(addr<SocketAddr>, new_port<u16>) {
    if socket_addr_is_v4(addr) {
        socket_addr_v4_store(addr).set_port_num(new_port)
        return
    }
    socket_addr_v6_store(addr).set_port_num(new_port)
}

fn socket_addr_into_inner(addr<SocketAddr>) sys.SocketAddrCRepr, u32 {
    if socket_addr_is_v4(addr) {
        repr<sys.SocketAddrCRepr> = new sys.SocketAddrCRepr {
            v4_store: socket_addr_v4_store(addr).into_inner()
        }
        return repr, sizeof(sys.SockaddrIn)
    }
    repr6<sys.SocketAddrCRepr> = new sys.SocketAddrCRepr {
        v6_store: socket_addr_v6_store(addr).into_inner()
    }
    return repr6, sizeof(sys.SockaddrIn6)
}
