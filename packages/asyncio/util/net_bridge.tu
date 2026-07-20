// Library `net` bridges for asyncio.net.
//
// Package asyncio.net has short-name `net`. Importing the library as
// `use net` / `use net as libnet` registers path "net" and poisons
// getPackage for local mem types. Call these from asyncio.util instead.

use net as libnet
use fmt
use string
use std

fn net_parse_ascii_bytes_bits(b<u8*>, len<i32>) i32, u64 {
    err<i32>, bits<u64> = libnet.parse_ascii_bytes_bits(b, len)
    return err, bits
}

fn net_strto_socket_addrs(host<string.String>) i32, std.Array {
    err<i32>, list<std.Array> = libnet.strto_socket_addrs(host)
    return err, list
}

fn net_socket_addr_from_bits(bits<u64>) libnet.SocketAddr {
    return bits.(libnet.SocketAddr)
}

fn net_socket_addr_to_bits(addr<libnet.SocketAddr>) u64 {
    return addr.(u64)
}

// Format SocketAddr as dotted-quad or full IPv6 bracket form for round-trip tests.
fn net_socket_addr_to_string_bits(bits<u64>) string.String {
    addr<libnet.SocketAddr> = bits.(libnet.SocketAddr)
    if libnet.socket_addr_is_v4(addr) {
        v4<libnet.SocketAddrV4> = libnet.socket_addr_v4_store(addr)
        ip<libnet.Ipv4Addr> = v4.ip()
        a<u8>, b<u8>, c<u8>, d<u8> = ip.octets()
        port<u16> = v4.port_num()
        return fmt.sprintf("%u.%u.%u.%u:%u", int(a), int(b), int(c), int(d), int(port))
    }
    v6<libnet.SocketAddrV6> = libnet.socket_addr_v6_store(addr)
    ip6<libnet.Ipv6Addr> = v6.ip()
    segs<u16*> = ip6.segments()
    port6<u16> = v6.port_num()
    return fmt.sprintf("[%x:%x:%x:%x:%x:%x:%x:%x]:%u",
        int(segs[0]), int(segs[1]), int(segs[2]), int(segs[3]),
        int(segs[4]), int(segs[5]), int(segs[6]), int(segs[7]), int(port6))
}
