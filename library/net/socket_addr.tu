use io
use sys

api SocketAddr {
    fn v4() i32 {
        return false
    }
    fn v6() i32 {
        return false
    }
    fn port() u16 {
        if this.v4() {
            addr<SocketAddrV4> = this
            return addr.port()
        }else {
            addr<SocketAddrV6> = this
            return addr.port()
        }
    }
    
    fn set_port(new_port<u16>) {
        if this.v4() {
            addr<SocketAddrV4> = this
            return addr.set_port(new_port)
        }else {
            addr<SocketAddrV6> = this
            return addr.set_port(new_port)
        }
    }
}

mem SocketAddrV4 {
    Ipv4Addr* ip
    u16 port
}

impl SocketAddr for SocketAddrV4 {
    fn v4() i32 {
        return true
    }
}

const SocketAddrV4::new(ip<Ipv4Addr>, port<u16>)  SocketAddrV4 {
    return new SocketAddrV4 { 
        ip: ip, 
        port: port 
    }
}

SocketAddrV4::ip() Ipv4Addr {
    return this.ip
}

SocketAddrV4::port()  u16 {
    return this.port
}

SocketAddrV4::set_port( new_port<u16>){
    this.port = new_port
}

SocketAddrV4::into_inner() sys.SockaddrIn {
    return new sys.SockaddrIn{
        sin_family: sys.AF_INET
        sin_port: this.port(),
        sin_addr: sys.InAddr{
            s_addr: this.ip().into_inner()
        }
    }
}

mem SocketAddrV6 {
    Ipv6Addr* ip
    u16 port
    u32 flowinfo,
    u32 scope_id
}

    
const SocketAddrV6::new(ip<Ipv6Addr>, port<u16>, flowinfo<u32>, scope_id<u32>) SocketAddrV6 {
    return new SocketAddrV6 { 
        ip: ip, 
        port: port, 
        flowinfo: flowinfo, 
        scope_id: scope_id 
    }
}

SocketAddrV6::ip() Ipv6Addr {
    return this.ip
}

SocketAddrV6::port() u16 {
    return this.port
}

SocketAddrV6::set_port( new_port<u16>) {
    this.port = new_port
}

SocketAddrV6::flowinfo() u32 {
    return this.flowinfo
}

SocketAddrV6::scope_id() u32 {
    return this.scope_id
}

SocketAddrV6::into_inner() sys.SockaddrIn6 {
    return new sys.SockaddrIn6 {
        sin6_family: sys.AF_INET6,
        sin6_port: this.port(),
        sin6_addr: sys.In6Addr {
            s6_addr: this.ip().into_inner()
        },
        sin6_flowinfo: this.flowinfo(),
        sin6_scope_id: this.scope_id(),
    }
}


fn resolve_socket_addr(lh<LookupHost>) i32, std.Array {
    p<i32> = lh.port()
    v<std.Array> = std.NewArray()

    loop {
        isnone<i32>,addr<SocketAddr> = lh.next()
        if isnone == None {
            break
        }
        addr.set_port(p)

        v.push(addr)
    }
    return Ok,v
}

fn strto_socket_addrs(s<string.String>) i32,std.Array,i32 {
    v<std.Array> = std.NewArray()
    // try to parse as a regular SocketAddr first
    err<i32> ,addr<SocketAddr> = SocketAddr::parse_ascii(s)
    if err == Ok {
        v.push(addr)
        return err, v
    }

    err,lookup<LookupHost> = sys.lookuphost_fromstr(s)
    if err != Ok {
        return err
    }
    err,ret<i64*> = resolve_socket_addr(lookup)
    return err,ret
}

