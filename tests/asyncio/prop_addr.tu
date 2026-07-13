// Property test (task 15.3): parse . format round-trip for SocketAddr.
//
// For random IPv4 and IPv6 addresses, format via socket_addr_to_string then
// parse back via parse_socket_addr and assert the octets / segments / port are
// preserved. Uses a deterministic LCG so failures are reproducible.

use fmt
use os
use io
use string
use net
use asyncio.net as anet

ITERS<i32> = 256

// LCG step (Knuth MMIX constants); returns the updated state.
fn lcg_next(s<u64>) u64 {
    return s * 6364136223846793005 + 1442695040888963407
}

// Build a v4 SocketAddr, round-trip it through string form, and assert equality.
fn check_v4(a<u8>, b<u8>, c<u8>, d<u8>, port<u16>) {
    ip<net.Ipv4Addr> = net.Ipv4Addr::new(a, b, c, d)
    v4<net.Ipv4Endpoint> = net.Ipv4Endpoint::new(ip, port)

    s<string.String> = anet.socket_addr_to_string(v4)
    err<i32>, back<net.SocketAddr> = anet.parse_socket_addr(s.str(), s.len())
    if err != io.Ok os.dief("v4 parse failed for round-trip")
    if libnet.endpoint_is_ipv4(back) == false os.die("v4 round-trip lost the v4 tag")

    a4<net.Ipv4Endpoint> = back
    rip<net.Ipv4Addr> = a4.ip()
    o0<u8>, o1<u8>, o2<u8>, o3<u8> = rip.octets()
    if o0 != a || o1 != b || o2 != c || o3 != d os.dief("v4 octet mismatch")
    if a4.port() != port os.dief("v4 port mismatch")
}

// Build a v6 SocketAddr, round-trip it, and assert segment / port equality.
fn check_v6(seg<u16*>, port<u16>) {
    ip6<net.Ipv6Addr> = net.Ipv6Addr::new(seg[0], seg[1], seg[2], seg[3], seg[4], seg[5], seg[6], seg[7])
    v6<net.Ipv6Endpoint> = net.Ipv6Endpoint::new(ip6, port, 0, 0)

    s<string.String> = anet.socket_addr_to_string(v6)
    err<i32>, back<net.SocketAddr> = anet.parse_socket_addr(s.str(), s.len())
    if err != io.Ok os.dief("v6 parse failed for round-trip")
    if libnet.endpoint_is_ipv4(back) os.die("v6 round-trip gained a v4 tag")

    a6<net.Ipv6Endpoint> = back
    rseg<u16*> = a6.ip().segments()
    for i<i32> = 0 ; i < 8 ; i += 1 {
        if rseg[i] != seg[i] os.dief("v6 segment mismatch")
    }
    if a6.port() != port os.dief("v6 port mismatch")
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

        check_v4((r0 & 0xFF).(u8), ((r0 >> 8) & 0xFF).(u8), ((r0 >> 16) & 0xFF).(u8), ((r0 >> 24) & 0xFF).(u8), (r1 & 0xFFFF).(u16))

        seg<u16:8> = null
        for j<i32> = 0 ; j < 8 ; j += 1 {
            st = lcg_next(st)
            seg[j] = ((st >> 24) & 0xFFFF).(u16)
        }
        st = lcg_next(st)
        check_v6(seg, (st & 0xFFFF).(u16))
    }

    fmt.println("prop_addr_parse_roundtrip passed")
}

fn main(){
    prop_addr_parse_roundtrip()
}
