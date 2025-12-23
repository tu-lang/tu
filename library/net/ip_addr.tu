use fmt

api IpAddr {
    fn v4() i32 { return false}
    fn v6() i32 { return false}
    fn string() string.String {
        if this.v4() {
            addr<Ipv4Addr> = this
            return addr.string()
        }else {
            addr<Ipv6Addr> = this
            return addr.string()
        }
    }
    fn cmp(other<IpAddr>) i32 {
        if this.v4() && other.v4() {
            addr1<Ipv4Addr> = this
            addr2<Ipv4Addr> = other
            if addr1.octets() == addr2.octets() {
                return true
            }
            return false
        }
        if this.v6() && other.v6() {
            addr1<Ipv6Addr> = this
            addr2<Ipv6Addr> = other
            p1<u64*> = addr1.octets()
            p2<u64*> = addr2.octets()
            if p1[0] == p2[0] && p1[1] == p2[1] {
                return true
            }
            return false
        }
        return false
    }
}

mem Ipv4Addr {
    u8 octets[4]
}

const Ipv4Addr::new(a<u8>, b<u8>, c<u8>, d<u8>) Ipv4Addr {
    return new Ipv4Addr { 
        octets: [a, b, c, d] 
    }
}

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
    return this.octets()
}

Ipv4Addr::string() string.String {
    strl<string.Str> = string.empty()
	strl = strl.catfmt(
        "%d.%d.%d.%d".(i8),
        this.octets[0],
        this.octets[1],
        this.octets[2],
        this.octets[3],
    )
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

const Ipv6Addr::new(a<u16>, b<u16>, c<u16>, d<u16>, e<u16>, f<u16>, g<u16>, h<u16>)  Ipv6Addr {
    return new Ipv6Addr {
        octets: [
            a,
            b,
            c,
            d,
            e,
            f,
            g,
            h
        ]
    }
}

LOCALHOST<Ipv6Addr:> = new Ipv6Addr {
    octets: [
        0, 0, 0, 0, 0, 0, 0, 1
    ]
}

UNSPECIFIED<Ipv6Addr:> = new Ipv6Addr{
    octets: [
        0, 0, 0, 0, 0, 0, 0, 0
    ]
}

// @return [u16:8]
Ipv6Addr::segments()  u16* {
    return &this.octets
}

// @return [u8:16]
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

