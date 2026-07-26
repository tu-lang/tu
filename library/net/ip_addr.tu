use fmt
use string
use sys

// IPv4 / IPv6 addresses (tustd::net::Ipv4Addr / Ipv6Addr).

mem Ipv4Addr {
    u8 octets[4]
}

const Ipv4Addr::new(a<u8>, b<u8>, c<u8>, d<u8>) Ipv4Addr {
    return new Ipv4Addr {
        octets: [a, b, c, d]
    }
}

// Mother: Ipv4Addr::LOCALHOST / UNSPECIFIED / BROADCAST (associated consts).
LOCALHOST<Ipv4Addr:> = new Ipv4Addr{
    octets: [127,0,0,1]
}

UNSPECIFIED<Ipv4Addr:> = new Ipv4Addr {
    octets: [0,0,0,0]
}

BROADCAST<Ipv4Addr:> = new Ipv4Addr {
    octets: [255,255,255,255]
}

Ipv4Addr::octets()  u8,u8,u8,u8 {
    return this.octets[0],
           this.octets[1],
           this.octets[2],
           this.octets[3]
}

Ipv4Addr::into_inner() u32 {
    // Mother: u32::from_ne_bytes(self.octets()) — host endian pack.
    o0<u8> = this.octets[0]
    o1<u8> = this.octets[1]
    o2<u8> = this.octets[2]
    o3<u8> = this.octets[3]
    a<u32> = o0.(u32)
    b<u32> = o1.(u32)
    c<u32> = o2.(u32)
    d<u32> = o3.(u32)
    return a | (b << 8) | (c << 16) | (d << 24)
}

Ipv4Addr::string() string.String {
    // catfmt supports %i/%u, not %d (%d prints the letter 'd').
    // Promote octets to i64 so %i / stringll2str see full integer args.
    a<i64> = 0
    b<i64> = 0
    c<i64> = 0
    d<i64> = 0
    a = this.octets[0]
    b = this.octets[1]
    c = this.octets[2]
    d = this.octets[3]
    strl<string.Str> = string.empty()
    strl = strl.catfmt(*"%i.%i.%i.%i", a, b, c, d)
    return string.S(strl)
}

const Ipv4Addr::from(octet<u8*>)  Ipv4Addr {
    return new Ipv4Addr {
        octets: [
            octet[0],
            octet[1],
            octet[2],
            octet[3]
        ]
    }
}

mem Ipv6Addr {
    u8 octets[16]
}

// Mother: Ipv6Addr::new — eight host u16 segments, each to_be, laid out as [u8;16].
const Ipv6Addr::new(a<u16>, b<u16>, c<u16>, d<u16>, e<u16>, f<u16>, g<u16>, h<u16>) Ipv6Addr {
    addr<Ipv6Addr> = new Ipv6Addr{}
    segs<u16*> = &addr.octets
    segs[0] = sys.u16_to_be(a)
    segs[1] = sys.u16_to_be(b)
    segs[2] = sys.u16_to_be(c)
    segs[3] = sys.u16_to_be(d)
    segs[4] = sys.u16_to_be(e)
    segs[5] = sys.u16_to_be(f)
    segs[6] = sys.u16_to_be(g)
    segs[7] = sys.u16_to_be(h)
    return addr
}

// Mother: Ipv6Addr::LOCALHOST = new(0,0,0,0,0,0,0,1) → octet[15]=1 on wire.
IPV6_LOCALHOST<Ipv6Addr:> = new Ipv6Addr {
    octets: [
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1
    ]
}

// Mother: Ipv6Addr::UNSPECIFIED.
IPV6_UNSPECIFIED<Ipv6Addr:> = new Ipv6Addr{
    octets: [
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0
    ]
}

// Scratch for host-order segments(); valid until the next segments() call.
IPV6_SEGS_HOST<u16:8> = null

// Mother: Ipv6Addr::segments — eight host-endian u16 groups (from_be of wire).
Ipv6Addr::segments() u16* {
    be<u16*> = &this.octets
    i<i32> = 0
    while i < 8 {
        IPV6_SEGS_HOST[i] = sys.u16_from_be(be[i])
        i += 1
    }
    return &IPV6_SEGS_HOST
}

Ipv6Addr::octets() u8* {
    return &this.octets
}

const Ipv6Addr::from_u16(segments<u16*>) Ipv6Addr {
    return Ipv6Addr::new(
        segments[0],
        segments[1],
        segments[2],
        segments[3],
        segments[4],
        segments[5],
        segments[6],
        segments[7],
    )
}

const Ipv6Addr::from_u8(segments<u8*>) Ipv6Addr {
    input<u64*> = &segments
    addr<Ipv6Addr> = new Ipv6Addr{}
    output<u64*> = &addr.octets

    output[0] = input[0]
    output[1] = input[1]

    return addr
}

Ipv6Addr::into_inner()  u8* {
    return this.octets()
}

Ipv6Addr::string() string.String {
    return string.S("(ipv6 addr)".(i8))
}
