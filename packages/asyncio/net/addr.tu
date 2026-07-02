// User-facing socket-address surface for asyncio.net.
//
// The address type is net.SocketAddr (library/net) on purpose: netio's socket
// layer (netio.net.udp.UdpSocket::bind, netio.net.tcp.stream.TcpStream::connect,
// netio.sys.*) all consume net.SocketAddr, so asyncio.net must speak the same
// type to feed those APIs.
//
// net's own parser (parse_ascii) and Ip*Addr::string() are still WIP, so parse
// and to_string are implemented here on top of net's working constructors and
// getters (Ipv4Addr::new / SocketAddrV4::new / octets() / segments() / port()).
// to_string emits the full, non-compressed IPv6 form ("[h:...:h]:port") and
// parse only accepts that full form, guaranteeing round-trip.

use net
use string
use io

// Parse a base-10 number from b[pos..len). Returns (ok, value, new_pos); ok == 0
// when no digit was consumed.
fn read_dec(b<u8*>, pos<i32>, len<i32>) i32, u32, i32 {
    v<u32> = 0
    start<i32> = pos
    while pos < len {
        c<u8> = b[pos]
        if c < '0'.(u8) || c > '9'.(u8) break
        v = v * 10 + (c - '0'.(u8)).(u32)
        pos += 1
    }
    if pos == start return 0, 0, pos
    return 1, v, pos
}

// Parse a base-16 number from b[pos..len). Returns (ok, value, new_pos); ok == 0
// when no hex digit was consumed.
fn read_hex(b<u8*>, pos<i32>, len<i32>) i32, u32, i32 {
    v<u32> = 0
    start<i32> = pos
    while pos < len {
        c<u8> = b[pos]
        d<i32> = -1
        if c >= '0'.(u8) && c <= '9'.(u8) {
            d = (c - '0'.(u8)).(i32)
        } else if c >= 'a'.(u8) && c <= 'f'.(u8) {
            d = (c - 'a'.(u8) + 10).(i32)
        } else if c >= 'A'.(u8) && c <= 'F'.(u8) {
            d = (c - 'A'.(u8) + 10).(i32)
        } else {
            break
        }
        v = v * 16 + d.(u32)
        pos += 1
    }
    if pos == start return 0, 0, pos
    return 1, v, pos
}

// Parse "a.b.c.d:port" into a net.SocketAddr (IPv4). Returns (io.Ok, addr) or
// (io.OtherParse, null).
fn parse_v4_with_port(b<u8*>, len<i32>) i32, net.SocketAddr {
    o<u8:4> = null
    pos<i32> = 0
    for i<i32> = 0 ; i < 4 ; i += 1 {
        if i > 0 {
            if pos >= len || b[pos] != '.'.(u8) return io.OtherParse, null
            pos += 1
        }
        ok<i32>, val<u32>, np<i32> = read_dec(b, pos, len)
        if ok == 0 || val > 255 return io.OtherParse, null
        o[i] = val.(u8)
        pos = np
    }
    if pos >= len || b[pos] != ':'.(u8) return io.OtherParse, null
    pos += 1
    pok<i32>, pval<u32>, pnp<i32> = read_dec(b, pos, len)
    if pok == 0 || pval > 65535 return io.OtherParse, null
    pos = pnp
    if pos != len return io.OtherParse, null
    ip<net.Ipv4Addr> = net.Ipv4Addr::new(o[0], o[1], o[2], o[3])
    v4<net.SocketAddrV4> = net.SocketAddrV4::new(ip, pval.(u16))
    return io.Ok, v4
}

// Parse "[h:h:h:h:h:h:h:h]:port" (full, non-compressed) into a net.SocketAddr
// (IPv6). Returns (io.Ok, addr) or (io.OtherParse, null).
fn parse_v6_with_port(b<u8*>, len<i32>) i32, net.SocketAddr {
    pos<i32> = 0
    if pos >= len || b[pos] != '['.(u8) return io.OtherParse, null
    pos += 1
    s<u16:8> = null
    for i<i32> = 0 ; i < 8 ; i += 1 {
        if i > 0 {
            if pos >= len || b[pos] != ':'.(u8) return io.OtherParse, null
            pos += 1
        }
        ok<i32>, val<u32>, np<i32> = read_hex(b, pos, len)
        if ok == 0 || val > 65535 return io.OtherParse, null
        s[i] = val.(u16)
        pos = np
    }
    if pos >= len || b[pos] != ']'.(u8) return io.OtherParse, null
    pos += 1
    if pos >= len || b[pos] != ':'.(u8) return io.OtherParse, null
    pos += 1
    pok<i32>, pval<u32>, pnp<i32> = read_dec(b, pos, len)
    if pok == 0 || pval > 65535 return io.OtherParse, null
    pos = pnp
    if pos != len return io.OtherParse, null
    ip6<net.Ipv6Addr> = net.Ipv6Addr::new(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7])
    v6<net.SocketAddrV6> = net.SocketAddrV6::new(ip6, pval.(u16), 0, 0)
    return io.Ok, v6
}

// Parse an "ip:port" literal into a net.SocketAddr. A leading '[' selects the
// IPv6 grammar, otherwise IPv4. Returns (io.Ok, addr) or (io.OtherParse, null).
fn parse_socket_addr(b<u8*>, len<i32>) i32, net.SocketAddr {
    if len == 0 return io.OtherParse, null
    if b[0] == '['.(u8) return parse_v6_with_port(b, len)
    return parse_v4_with_port(b, len)
}

// Format a net.SocketAddr as "a.b.c.d:port" (IPv4) or "[h:...:h]:port" (IPv6,
// full form, lowercase hex). Round-trips through parse_socket_addr.
fn socket_addr_to_string(addr<net.SocketAddr>) string.String {
    sl<string.Str> = string.empty()
    if addr.v4() {
        a4<net.SocketAddrV4> = addr
        ip<net.Ipv4Addr> = a4.ip()
        o0<u8>, o1<u8>, o2<u8>, o3<u8> = ip.octets()
        sl = sl.catfmt("%u.%u.%u.%u:%u".(i8), o0, o1, o2, o3, a4.port())
        return string.S(sl)
    }
    a6<net.SocketAddrV6> = addr
    ip6<net.Ipv6Addr> = a6.ip()
    segs<u16*> = ip6.segments()
    hexd<i8*> = "0123456789abcdef".(i8)
    sl = sl.putc('['.(i8))
    for i<i32> = 0 ; i < 8 ; i += 1 {
        if i > 0 sl = sl.putc(':'.(i8))
        seg<u16> = segs[i]
        sl = sl.putc(hexd[(seg >> 12) & 0xF])
        sl = sl.putc(hexd[(seg >> 8) & 0xF])
        sl = sl.putc(hexd[(seg >> 4) & 0xF])
        sl = sl.putc(hexd[seg & 0xF])
    }
    sl = sl.putc(']'.(i8))
    sl = sl.catfmt(":%u".(i8), a6.port())
    return string.S(sl)
}

// Identity resolution for an already-parsed address (tokio's ToSocketAddrs for
// the SocketAddr case). net.SocketAddr is itself the polymorphic api, so no
// extra api is introduced; host-name resolution is async (net.lookup, 15.4).
fn to_socket_addrs(addr<net.SocketAddr>) i32, net.SocketAddr {
    return io.Ok, addr
}
