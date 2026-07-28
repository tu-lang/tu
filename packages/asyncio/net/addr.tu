// User-facing socket-address surface for asyncio.net.
//
// Parsing/formatting delegates to library/net via asyncio.util bridges
// (this package short-name is `net` and must not `use net` or getPackage
// poisons local mem types). Typed Mem APIs live in util; these wrappers
// delegate there for callers that import asyncio.net as anet.

use asyncio.util
use io
use string

// Parse socket-address bytes; returns (err, SocketAddr) via util bridge.
fn parse_socket_addr(b<u8*>, len<i32>) i32, u64 {
    err<i32>, addr = util.net_parse_ascii_bytes(b, len)
    if err != io.Ok return err, 0
    return err, addr.(u64)
}

// Identity resolution for an already-parsed address (typed bits in, bits out).
fn to_socket_addrs(addr<u64>) i32, u64 {
    ok_code<i32> = io.Ok
    return ok_code, addr
}

// Format a SocketAddr to ASCII for parse round-trip tests.
fn socket_addr_to_string(addr<u64>) string.String {
    sa = util.net_socket_addr_from_bits(addr)
    return util.net_socket_addr_to_string(sa)
}
