// Property test (task 15.3): parse . format round-trip for SocketAddr.
//
// For random IPv4 and IPv6 addresses, format via socket_addr_to_string then
// parse back via parse_socket_addr and assert the octets / segments / port are
// preserved. Uses a deterministic LCG so failures are reproducible.
//
// Note: do not pass stack `u16:8` as `u16*` — that pointer decay segfaults.
// Carry IPv6 segments in a heap mem instead.

use fmt
use os
use io
use string
use std
use net
use asyncio.net as anet
use asyncio.io as aio
use asyncio.util

ITERS<i32> = 256

// Eight host-order IPv6 segments for the LCG round-trip loop.
mem Seg8 {
    u16 v0
    u16 v1
    u16 v2
    u16 v3
    u16 v4
    u16 v5
    u16 v6
    u16 v7
}

// LCG step (Knuth MMIX constants); returns the updated state.
fn lcg_next(s<u64>) u64 {
    return s * 6364136223846793005 + 1442695040888963407
}

// Build a v4 SocketAddr, round-trip it through string form, and assert equality.
fn check_v4(a<u8>, b<u8>, c<u8>, d<u8>, port_num<u16>) {
    ip<net.Ipv4Addr> = net.Ipv4Addr::new(a, b, c, d)
    v4<net.SocketAddrV4> = net.SocketAddrV4::new(ip, port_num)
    addr<net.SocketAddr> = net.socket_addr_from_v4(v4)

    s<string.String> = util.net_socket_addr_to_string(addr)
    err<i32>, back<net.SocketAddr> = util.net_parse_ascii_bytes(s.str(), std.strlen(s.str()))
    if err != io.Ok os.dief("v4 parse failed for round-trip")
    if net.socket_addr_is_v4(back) == false os.die("v4 round-trip lost the v4 tag")

    a4<net.SocketAddrV4> = net.socket_addr_v4_store(back)
    rip<net.Ipv4Addr> = a4.ip()
    o0<u8>, o1<u8>, o2<u8>, o3<u8> = rip.octets()
    if o0 != a || o1 != b || o2 != c || o3 != d os.dief("v4 octet mismatch")
    if a4.port_num() != port_num os.dief("v4 port mismatch")
}

// Build a v6 SocketAddr, round-trip it, and assert segment / port equality.
fn check_v6(seg<Seg8>, port_num<u16>) {
    ip6<net.Ipv6Addr> = net.Ipv6Addr::new(seg.v0, seg.v1, seg.v2, seg.v3, seg.v4, seg.v5, seg.v6, seg.v7)
    v6<net.SocketAddrV6> = net.SocketAddrV6::new(ip6, port_num, 0, 0)
    addr<net.SocketAddr> = net.socket_addr_from_v6(v6)

    s<string.String> = util.net_socket_addr_to_string(addr)
    err<i32>, back<net.SocketAddr> = util.net_parse_ascii_bytes(s.str(), std.strlen(s.str()))
    if err != io.Ok os.dief("v6 parse failed for round-trip")
    if net.socket_addr_is_v4(back) os.die("v6 round-trip gained a v4 tag")

    a6<net.SocketAddrV6> = net.socket_addr_v6_store(back)
    rseg<u16*> = a6.ip().segments()
    if rseg[0] != seg.v0 os.dief("v6 segment mismatch")
    if rseg[1] != seg.v1 os.dief("v6 segment mismatch")
    if rseg[2] != seg.v2 os.dief("v6 segment mismatch")
    if rseg[3] != seg.v3 os.dief("v6 segment mismatch")
    if rseg[4] != seg.v4 os.dief("v6 segment mismatch")
    if rseg[5] != seg.v5 os.dief("v6 segment mismatch")
    if rseg[6] != seg.v6 os.dief("v6 segment mismatch")
    if rseg[7] != seg.v7 os.dief("v6 segment mismatch")
    if a6.port_num() != port_num os.dief("v6 port mismatch")
}

// Feature: packages-asyncio-runtime, Property: SocketAddr to_string/parse
// round-trip preserves octets, segments and port for random v4/v6 addresses.
fn prop_addr_parse_roundtrip(){
    fmt.println("prop_addr_parse_roundtrip test")
    st<u64> = 0x9e3779b97f4a7c15

    for iter<i32> = 0 ; iter < ITERS ; iter += 1 {
        st = lcg_next(st)
        r0<u64> = st >> 24
        st = lcg_next(st)
        r1<u64> = st >> 24

        t0<u64> = r0 & 0xFF
        b0<u8> = t0.(u8)
        t1<u64> = (r0 >> 8) & 0xFF
        b1<u8> = t1.(u8)
        t2<u64> = (r0 >> 16) & 0xFF
        b2<u8> = t2.(u8)
        t3<u64> = (r0 >> 24) & 0xFF
        b3<u8> = t3.(u8)
        port_bits<u64> = r1 & 0xFFFF
        port_v4<u16> = port_bits.(u16)
        check_v4(b0, b1, b2, b3, port_v4)

        seg<Seg8> = new Seg8
        st = lcg_next(st)
        sb0<u64> = (st >> 24) & 0xFFFF
        seg.v0 = sb0.(u16)
        st = lcg_next(st)
        sb1<u64> = (st >> 24) & 0xFFFF
        seg.v1 = sb1.(u16)
        st = lcg_next(st)
        sb2<u64> = (st >> 24) & 0xFFFF
        seg.v2 = sb2.(u16)
        st = lcg_next(st)
        sb3<u64> = (st >> 24) & 0xFFFF
        seg.v3 = sb3.(u16)
        st = lcg_next(st)
        sb4<u64> = (st >> 24) & 0xFFFF
        seg.v4 = sb4.(u16)
        st = lcg_next(st)
        sb5<u64> = (st >> 24) & 0xFFFF
        seg.v5 = sb5.(u16)
        st = lcg_next(st)
        sb6<u64> = (st >> 24) & 0xFFFF
        seg.v6 = sb6.(u16)
        st = lcg_next(st)
        sb7<u64> = (st >> 24) & 0xFFFF
        seg.v7 = sb7.(u16)
        st = lcg_next(st)
        port6_bits<u64> = st & 0xFFFF
        check_v6(seg, port6_bits.(u16))
    }

    fmt.println("prop_addr_parse_roundtrip passed")
}

// Nested package alias + const static: aio.ReadBuf::from_ptr (optimize §4).
fn test_nested_pkg_static_call(){
    fmt.println("test nested pkg static call")
    cap<u64> = 8
    p<u8*> = null
    rb<aio.ReadBuf> = aio.ReadBuf::from_ptr(p, cap)
    if rb.cap != 8 os.die("aio.ReadBuf::from_ptr cap != 8")
    if rb.filled != 0 os.die("aio.ReadBuf::from_ptr filled != 0")
    fmt.println("test nested pkg static call passed")
}

fn main(){
    prop_addr_parse_roundtrip()
    test_nested_pkg_static_call()
}
