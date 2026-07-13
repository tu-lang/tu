use io
use sys

api SocketAddr {
    fn is_v4() i32 {
        return false
    }
    fn is_v6() i32 {
        return false
    }
    fn get_port() u16 {
        if this.is_v4() {
            addr<SocketAddrV4> = this
            return addr.port()
        }else {
            addr<SocketAddrV6> = this
            return addr.port()
        }
    }

    fn assign_port(new_port<u16>) {
        if this.is_v4() {
            addr<SocketAddrV4> = this
            return addr.set_port(new_port)
        }else {
            addr<SocketAddrV6> = this
            return addr.set_port(new_port)
        }
    }
    fn into_inner() sys.SocketAddrCRepr, u32 {
        match this.is_v4() {
            true : {
                addr<SocketAddrV4> = this
                sockaddr<i64*> = new sys.SocketAddrCRepr {
                    v4_store: addr.into_inner()
                }
                return sockaddr, sizeof(sys.SockaddrIn)
            }
            false: {
                addr<SocketAddrV6> = this
                sockaddr<i64*> = new sys.SocketAddrCRepr {
                    v6_store: addr.into_inner()
                }
                return sockaddr, sizeof(sys.SockaddrIn6)
            }
        }
    }
}

mem SocketAddrV4 {
    Ipv4Addr* host_v4
    u16 port_val
}

impl SocketAddr for SocketAddrV4 {
    fn is_v4() i32 {
        return true
    }
    fn is_v6() i32 {
        return 0
    }
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

impl SocketAddr for SocketAddrV6 {
    fn is_v4() i32 {
        return 0
    }
    fn is_v6() i32 {
        return 1
    }
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
