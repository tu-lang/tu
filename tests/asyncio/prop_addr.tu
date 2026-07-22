// Property test (task 15.3): parse . format round-trip for SocketAddr.
//
// For random IPv4 and IPv6 addresses, format via socket_addr_to_string then
// parse back via parse_socket_addr and assert the octets / segments / port are
// preserved. Uses a deterministic LCG so failures are reproducible.

use fmt
use os
use io
use string
use std
use net
use asyncio.net as anet

ITERS<i32> = 256

// LCG step (Knuth MMIX constants); returns the updated state.
fn lcg_next(s<u64>) u64 {
    return s * 6364136223846793005 + 1442695040888963407
}

// Build a v4 SocketAddr, round-trip it through string form, and assert equality.
fn check_v4(a<u8>, b<u8>, c<u8>, d<u8>, port_num<u16>) {
    ip<net.Ipv4Addr> = net.Ipv4Addr::new(a, b, c, d)
    v4<net.SocketAddrV4> = net.SocketAddrV4::new(ip, port_num)
    addr<net.SocketAddr> = net.socket_addr_from_v4(v4)

    s<string.String> = anet.socket_addr_to_string(addr.(u64))
    err<i32>, back_bits<u64> = anet.parse_socket_addr(s.str(), std.strlen(s.str()))
    if err != io.Ok os.dief("v4 parse failed for round-trip")
    back<net.SocketAddr> = back_bits.(net.SocketAddr)
    if net.socket_addr_is_v4(back) == false os.die("v4 round-trip lost the v4 tag")

    a4<net.SocketAddrV4> = net.socket_addr_v4_store(back)
    rip<net.Ipv4Addr> = a4.ip()
    o0<u8>, o1<u8>, o2<u8>, o3<u8> = rip.octets()
    if o0 != a || o1 != b || o2 != c || o3 != d os.dief("v4 octet mismatch")
    if a4.port_num() != port_num os.dief("v4 port mismatch")
}

// Build a v6 SocketAddr, round-trip it, and assert segment / port equality.
fn check_v6(seg<u16*>, port_num<u16>) {
    ip6<net.Ipv6Addr> = net.Ipv6Addr::new(seg[0], seg[1], seg[2], seg[3], seg[4], seg[5], seg[6], seg[7])
    v6<net.SocketAddrV6> = net.SocketAddrV6::new(ip6, port_num, 0, 0)
    addr<net.SocketAddr> = net.socket_addr_from_v6(v6)

    s<string.String> = anet.socket_addr_to_string(addr.(u64))
    err<i32>, back_bits<u64> = anet.parse_socket_addr(s.str(), std.strlen(s.str()))
    if err != io.Ok os.dief("v6 parse failed for round-trip")
    back<net.SocketAddr> = back_bits.(net.SocketAddr)
    if net.socket_addr_is_v4(back) os.die("v6 round-trip gained a v4 tag")

    a6<net.SocketAddrV6> = net.socket_addr_v6_store(back)
    rseg<u16*> = a6.ip().segments()
    for i<i32> = 0 ; i < 8 ; i += 1 {
        if rseg[i] != seg[i] os.dief("v6 segment mismatch")
    }
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

        seg<u16:8> = null
        for j<i32> = 0 ; j < 8 ; j += 1 {
        st = lcg_next(st)
        seg_bits<u64> = (st >> 24) & 0xFFFF
        seg[j] = seg_bits.(u16)
    }
    st = lcg_next(st)
    port6_bits<u64> = st & 0xFFFF
    check_v6(seg, port6_bits.(u16))
    }

    fmt.println("prop_addr_parse_roundtrip passed")
}

fn main(){
    prop_addr_parse_roundtrip()
}
