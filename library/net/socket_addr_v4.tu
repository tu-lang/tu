use sys

// IPv4 socket endpoint (tokio SocketAddrV4).

mem SocketAddrV4 {
    Ipv4Addr* host_v4
    u16 port_val
}

const SocketAddrV4::new(host<Ipv4Addr>, port_num<u16>) SocketAddrV4 {
    return new SocketAddrV4 { host_v4: host, port_val: port_num }
}

fn socket_addr_v4_from_ipv4_port(host<Ipv4Addr>, port_num<u16>) SocketAddrV4 {
    return SocketAddrV4::new(host, port_num)
}

SocketAddrV4::ip() Ipv4Addr {
    return this.host_v4
}

SocketAddrV4::port_num() u16 {
    return this.port_val
}

SocketAddrV4::set_port_num(new_port<u16>) {
    this.port_val = new_port
}

SocketAddrV4::into_inner() sys.SockaddrIn {
    return new sys.SockaddrIn{
        sin_family: sys.AF_INET,
        sin_port: this.port_val,
        sin_addr: sys.InAddr{
            s_addr: this.host_v4.into_inner()
        }
    }
}

fn socket_addr_v4_from_raw(raw<u64>) SocketAddrV4 {
    return raw.(SocketAddrV4)
}
