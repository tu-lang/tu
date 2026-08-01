// User-facing socket-address surface for asyncio.net.
// Parsing/formatting uses library `net` (bare `use net` is safe after
// global full_package / getImport packages[] priority).

use net
use io
use string
use asyncio.util

// Parse socket-address bytes; returns (err, SocketAddr bits).
fn parse_socket_addr(b<u8*>, len<i32>) i32, u64 {
    err<i32>, bits<u64> = net.parse_ascii_bytes_bits(b, len)
    if err != io.Ok return err, 0
    return err, bits
}

// Identity resolution for an already-parsed address (typed bits in, bits out).
fn to_socket_addrs(addr<u64>) i32, u64 {
    ok_code<i32> = io.Ok
    return ok_code, addr
}

// Format a SocketAddr to ASCII for parse round-trip tests.
fn socket_addr_to_string(addr<u64>) string.String {
    sa<net.SocketAddr> = net.socket_addr_from_bits(addr)
    return util.net_socket_addr_to_string(sa)
}
