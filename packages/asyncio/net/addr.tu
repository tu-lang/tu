// User-facing socket-address surface for asyncio.net.
//
// Parsing/formatting delegates to library/net
// via asyncio.util bridges (this package short-name is `net` and must not
// `use net` or getPackage poisons local mem types).

use asyncio.util
use string

// Parse socket-address bytes (delegates to net.parse_ascii_bytes).
// Returns (err, SocketAddr bits).
fn parse_socket_addr(b<u8*>, len<i32>) i32, u64 {
    err<i32>, bits<u64> = util.net_parse_ascii_bytes_bits(b, len)
    return err, bits
}

// Identity resolution for an already-parsed address.
fn to_socket_addrs(addr_bits<u64>) i32, u64 {
    ok_code<i32> = 1
    return ok_code, addr_bits
}

// Format a SocketAddr (u64 bits) to ASCII for parse round-trip tests.
fn socket_addr_to_string(addr_bits<u64>) string.String {
    return util.net_socket_addr_to_string_bits(addr_bits)
}
