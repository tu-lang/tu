use sys

// IPv6 socket endpoint (tokio SocketAddrV6).

mem SocketAddrV6 {
    Ipv6Addr* host_v6
    u16 port_val
    u32 flow_bits, scope_bits
}

const SocketAddrV6::new(host<Ipv6Addr>, port_num<u16>, flowinfo<u32>, scope_id<u32>) SocketAddrV6 {
    return new SocketAddrV6 {
        host_v6: host,
        port_val: port_num,
        flow_bits: flowinfo,
        scope_bits: scope_id
    }
}

fn socket_addr_v6_from_parts(host<Ipv6Addr>, port_num<u16>, flowinfo<u32>, scope_id<u32>) SocketAddrV6 {
    return SocketAddrV6::new(host, port_num, flowinfo, scope_id)
}

SocketAddrV6::ip() Ipv6Addr {
    return this.host_v6
}

SocketAddrV6::port_num() u16 {
    return this.port_val
}

SocketAddrV6::set_port_num(new_port<u16>) {
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
        sin6_port: sys.u16_to_be(this.port_val),
        sin6_flowinfo: this.flow_bits,
        sin6_scope_id: this.scope_bits,
    }
    oct<u64*> = this.host_v6.into_inner()
    p<u64*> = &addr.sin6_addr.s6_addr
    p[0] = oct[0]
    p[1] = oct[1]
    return addr
}

fn socket_addr_v6_from_raw(raw<u64>) SocketAddrV6 {
    return raw.(SocketAddrV6)
}
