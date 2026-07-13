use io
use sys

ADDR_V4_KIND<i32> = 4
ADDR_V6_KIND<i32> = 6

// Tagged socket address; avoids api/impl SocketAddr (compiler object-func trap).
mem SocketAddr {
    i32 kind
    SocketAddrV4* v4_store
    SocketAddrV6* v6_store
}

fn socket_addr_from_v4(v4<SocketAddrV4>) SocketAddr {
    return new SocketAddr { kind: ADDR_V4_KIND, v4_store: v4, v6_store: null }
}

fn socket_addr_from_v6(v6<SocketAddrV6>) SocketAddr {
    return new SocketAddr { kind: ADDR_V6_KIND, v4_store: null, v6_store: v6 }
}

fn socket_addr_is_v4(addr<SocketAddr>) i32 {
    return addr.kind == ADDR_V4_KIND
}

fn socket_addr_is_v6(addr<SocketAddr>) i32 {
    return addr.kind == ADDR_V6_KIND
}

fn socket_addr_get_port(addr<SocketAddr>) u16 {
    if socket_addr_is_v4(addr) {
        return addr.v4_store.port()
    }
    return addr.v6_store.port()
}

fn socket_addr_assign_port(addr<SocketAddr>, new_port<u16>) {
    if socket_addr_is_v4(addr) {
        addr.v4_store.set_port(new_port)
        return
    }
    addr.v6_store.set_port(new_port)
}

fn socket_addr_into_inner(addr<SocketAddr>) sys.SocketAddrCRepr, u32 {
    if socket_addr_is_v4(addr) {
        repr<sys.SocketAddrCRepr> = new sys.SocketAddrCRepr {
            v4_store: addr.v4_store.into_inner()
        }
        return repr, sizeof(sys.SockaddrIn)
    }
    repr6<sys.SocketAddrCRepr> = new sys.SocketAddrCRepr {
        v6_store: addr.v6_store.into_inner()
    }
    return repr6, sizeof(sys.SockaddrIn6)
}

mem SocketAddrV4 {
    Ipv4Addr* host_v4
    u16 port_val
}

const SocketAddrV4::new(host<Ipv4Addr>, port<u16>)  SocketAddrV4 {
    return new SocketAddrV4 {
        host_v4: host,
        port_val: port
    }
}

SocketAddrV4::ip() Ipv4Addr {
    return this.host_v4
}

SocketAddrV4::port()  u16 {
    return this.port_val
}

SocketAddrV4::set_port( new_port<u16>){
    this.port_val = new_port
}

SocketAddrV4::into_inner() sys.SockaddrIn {
    return new sys.SockaddrIn{
        sin_family: sys.AF_INET,
        sin_port: this.port(),
        sin_addr: sys.InAddr{
            s_addr: this.ip().into_inner()
        }
    }
}

mem SocketAddrV6 {
    Ipv6Addr* host_v6
    u16 port_val
    u32 flow_bits, scope_bits
}

const SocketAddrV6::new(host<Ipv6Addr>, port<u16>, flowinfo<u32>, scope_id<u32>) SocketAddrV6 {
    return new SocketAddrV6 {
        host_v6: host,
        port_val: port,
        flow_bits: flowinfo,
        scope_bits: scope_id
    }
}

SocketAddrV6::ip() Ipv6Addr {
    return this.host_v6
}

SocketAddrV6::port() u16 {
    return this.port_val
}

SocketAddrV6::set_port( new_port<u16>) {
    this.port_val = new_port
}

SocketAddrV6::flowinfo() u32 {
    return this.flow_bits
}

SocketAddrV6::scope_id() u32 {
    return this.scope_bits
}

SocketAddrV6::into_inner() sys.SockaddrIn6 {
    addr<sys.SockaddrIn6> = new sys.SockaddrIn6 {
        sin6_family: sys.AF_INET6,
        sin6_port: this.port(),
        sin6_flowinfo: this.flowinfo(),
        sin6_scope_id: this.scope_id(),
    }
    oct<u64*> = this.ip().into_inner()
    p<u64*> = &addr.sin6_addr.s6_addr
    p[0] = oct[0]
    p[1] = oct[1]
    return addr
}

fn strto_socket_addrs(s<string.String>) i32, std.Array {
    v<std.Array> = std.NewArray()
    return io.OtherParse, v
}
