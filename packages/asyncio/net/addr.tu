// User-facing socket-address surface for asyncio.net.
//
// Mirrors tokio::net::addr — parsing/formatting delegates to library/net
// (tustd::net::parser / SocketAddr::parse_ascii), same as tokio → std::net.

use net as libnet
use string
use io as libio

// Parse bytes like tustd SocketAddr::parse_ascii / tokio str::parse.
fn parse_socket_addr(b<u8*>, len<i32>) i32, libnet.SocketAddr {
    return libnet.parse_ascii_bytes(b, len)
}

// Format like std::net::SocketAddr Display (via library/net helpers).
fn socket_addr_to_string(addr<libnet.SocketAddr>) string.String {
    return libnet.socket_addr_to_string(addr)
}

// Identity resolution for an already-parsed address (tokio ToSocketAddrs for SocketAddr).
fn to_socket_addrs(addr<libnet.SocketAddr>) i32, libnet.SocketAddr {
    return libio.Ok, addr
}
