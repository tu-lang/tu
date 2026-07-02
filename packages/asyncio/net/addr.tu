// User-facing socket-address types for asyncio.net. Self-contained: does not
// depend on library/net (whose parser/string layer is an unverified draft).
// Only verified Tu constructs are used (fixed arrays, casts, string.Str
// catfmt/%u, hand-rolled hex).
//
// Design note (task 15.1/15.2): instead of the spec's `void* inner`, SocketAddr
// holds two nullable typed pointers (one per family) to avoid raw u64 casts.
// to_string emits the full, non-compressed IPv6 form ("[h:h:h:h:h:h:h:h]:port")
// so parse -> to_string -> parse round-trips; "::" compression is not produced
// and only the full form is accepted by parse.

use string
use io

// Address family tags (4 = IPv4, 6 = IPv6).
FAMILY_V4<i32> = 4
FAMILY_V6<i32> = 6

// IPv4 socket address: four octets plus a port (host byte order).
mem SocketAddrV4 {
    u8  octets[4]
    u16 port
}

// IPv6 socket address: eight 16-bit segments plus port, flow label and scope.
mem SocketAddrV6 {
    u16 segs[8]
    u16 port
    u32 flow
    u32 scope
}

// Family-tagged address. Exactly one of v4 / v6 is non-null, per `family`.
mem SocketAddr {
    i32 family          // FAMILY_V4 or FAMILY_V6
    SocketAddrV4* v4    // set when family == FAMILY_V4, else null
    SocketAddrV6* v6    // set when family == FAMILY_V6, else null
}

// Build an IPv4 address from four octets and a port.
const SocketAddrV4::new(a<u8>, b<u8>, c<u8>, d<u8>, port<u16>) SocketAddrV4 {
    return new SocketAddrV4 { octets: [a, b, c, d], port: port }
}

// Build an IPv6 address from eight segments, a port, flow label and scope id.
const SocketAddrV6::new(s0<u16>, s1<u16>, s2<u16>, s3<u16>, s4<u16>, s5<u16>, s6<u16>, s7<u16>, port<u16>, flow<u32>, scope<u32>) SocketAddrV6 {
    return new SocketAddrV6 {
        segs: [s0, s1, s2, s3, s4, s5, s6, s7],
        port: port,
        flow: flow,
        scope: scope
    }
}

// Wrap a concrete IPv4 address as a family-tagged SocketAddr.
const SocketAddr::from_v4(a<SocketAddrV4>) SocketAddr {
    return new SocketAddr { family: FAMILY_V4, v4: a, v6: null }
}

// Wrap a concrete IPv6 address as a family-tagged SocketAddr.
const SocketAddr::from_v6(a<SocketAddrV6>) SocketAddr {
    return new SocketAddr { family: FAMILY_V6, v4: null, v6: a }
}

// True when this address is IPv4 / IPv6 respectively.
SocketAddr::is_v4() i32 { return this.family == FAMILY_V4 }
SocketAddr::is_v6() i32 { return this.family == FAMILY_V6 }

// Port in host byte order, regardless of family.
SocketAddr::port() u16 {
    if this.family == FAMILY_V4 return this.v4.port
    return this.v6.port
}

// Format as "a.b.c.d:port" (IPv4) or "[h:h:h:h:h:h:h:h]:port" (IPv6, full form,
// lowercase hex). Round-trips through parse_socket_addr.
SocketAddr::to_string() string.String {
    sl<string.Str> = string.empty()
    if this.family == FAMILY_V4 {
        v<SocketAddrV4> = this.v4
        sl = sl.catfmt(
            "%u.%u.%u.%u:%u".(i8),
            v.octets[0], v.octets[1], v.octets[2], v.octets[3],
            v.port
        )
        return string.S(sl)
    }
    v6<SocketAddrV6> = this.v6
    hexd<i8*> = "0123456789abcdef".(i8)
    sl = sl.putc('['.(i8))
    for i<i32> = 0 ; i < 8 ; i += 1 {
        if i > 0 sl = sl.putc(':'.(i8))
        seg<u16> = v6.segs[i]
        sl = sl.putc(hexd[(seg >> 12) & 0xF])
        sl = sl.putc(hexd[(seg >> 8) & 0xF])
        sl = sl.putc(hexd[(seg >> 4) & 0xF])
        sl = sl.putc(hexd[seg & 0xF])
    }
    sl = sl.putc(']'.(i8))
    sl = sl.catfmt(":%u".(i8), v6.port)
    return string.S(sl)
}

// Read a base-10 number from b[pos..len). Returns (ok, value, new_pos); ok == 0
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

// Read a base-16 number from b[pos..len). Returns (ok, value, new_pos); ok == 0
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

// Parse "a.b.c.d:port" into an IPv4 SocketAddr. Returns (io.Ok, addr) or
// (io.OtherParse, null).
fn parse_v4_with_port(b<u8*>, len<i32>) i32, SocketAddr {
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
    v4<SocketAddrV4> = SocketAddrV4::new(o[0], o[1], o[2], o[3], pval.(u16))
    return io.Ok, SocketAddr::from_v4(v4)
}

// Parse "[h:h:h:h:h:h:h:h]:port" (full, non-compressed) into an IPv6
// SocketAddr. Returns (io.Ok, addr) or (io.OtherParse, null).
fn parse_v6_with_port(b<u8*>, len<i32>) i32, SocketAddr {
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
    v6<SocketAddrV6> = SocketAddrV6::new(s[0], s[1], s[2], s[3], s[4], s[5], s[6], s[7], pval.(u16), 0, 0)
    return io.Ok, SocketAddr::from_v6(v6)
}

// Parse an "ip:port" literal into a SocketAddr. A leading '[' selects the IPv6
// grammar, otherwise IPv4. Returns (io.Ok, addr) or (io.OtherParse, null).
fn parse_socket_addr(b<u8*>, len<i32>) i32, SocketAddr {
    if len == 0 return io.OtherParse, null
    if b[0] == '['.(u8) return parse_v6_with_port(b, len)
    return parse_v4_with_port(b, len)
}

// Types accepted where a socket address is expected (tokio's ToSocketAddrs).
// Returns (err, addr); concrete addresses resolve to themselves. Host-name
// resolution is async and lives in net.lookup (task 15.4).
api ToSocketAddrs {
    fn to_socket_addrs() (i32, SocketAddr)
}

// A family-tagged SocketAddr resolves to itself.
impl ToSocketAddrs for SocketAddr {
    fn to_socket_addrs() i32, SocketAddr {
        return io.Ok, this
    }
}

// A concrete IPv4 address wraps into a SocketAddr.
impl ToSocketAddrs for SocketAddrV4 {
    fn to_socket_addrs() i32, SocketAddr {
        return io.Ok, SocketAddr::from_v4(this)
    }
}

// A concrete IPv6 address wraps into a SocketAddr.
impl ToSocketAddrs for SocketAddrV6 {
    fn to_socket_addrs() i32, SocketAddr {
        return io.Ok, SocketAddr::from_v6(this)
    }
}
