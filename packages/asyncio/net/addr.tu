// User-facing socket-address surface. The full SocketAddr family (the
// SocketAddr api, SocketAddrV4 / SocketAddrV6, Ipv4Addr / Ipv6Addr, ascii
// parsing, C-repr conversion and DNS lookup) already lives in library `net`;
// asyncio.net re-exports it through thin factories so callers stay within
// `use asyncio.net` and never reach into the net library directly.
//
// Design deviation (task 15.1/15.2): the spec's standalone
// `mem SocketAddr { family; inner }` and separate `api ToSocketAddrs` are
// dropped in favour of reusing library `net`. SocketAddr there is already a
// polymorphic api, and Tu has no cross-package impl, so ToSocketAddrs cannot
// be attached onto library net's mems. The tokio ToSocketAddrs role is served
// by the package-level to_socket_addrs / parse_socket_addr helpers below.

use net as lnet
use io

// Build an IPv4 socket address from four octets and a port.
fn socket_addr_v4(a<u8>, b<u8>, c<u8>, d<u8>, port<u16>) lnet.SocketAddrV4 {
    ip<lnet.Ipv4Addr> = lnet.Ipv4Addr::new(a, b, c, d)
    return lnet.SocketAddrV4::new(ip, port)
}

// Parse an "ip:port" literal (IPv4 or IPv6) into a SocketAddr. Returns
// (io.Ok, addr) on success or the parser's error code with a null addr.
fn parse_socket_addr(b<u8*>, len<i32>) i32, lnet.SocketAddr {
    return lnet.SocketAddr::parse_ascii(b, len)
}

// Identity resolution for an already-parsed SocketAddr (tokio's ToSocketAddrs
// for the SocketAddr case). Host-name resolution is async and lives in
// net.lookup (task 15.4); string literals go through parse_socket_addr.
fn to_socket_addrs(addr<lnet.SocketAddr>) i32, lnet.SocketAddr {
    return io.Ok, addr
}
