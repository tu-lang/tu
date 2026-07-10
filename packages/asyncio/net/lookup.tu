// Host resolution for asyncio.net (tokio's lookup_host).
//
// V1: numeric "ip:port" literals resolve synchronously via parse_socket_addr
// and yield a single-entry array. Hostname DNS (getaddrinfo) is deferred until
// the blocking pool + a working resolver are wired -- library's sys.LookupHost
// path is still WIP -- so non-numeric hosts return io.Unsupported with an empty
// array. Kept async to match the awaitable public contract; the DNS variant
// will route through runtime.blocking spawn_mandatory_blocking.

use net as libnet
use io as libio
use string
use std

// Resolve `host` ("ip:port") to a list of libnet.SocketAddr. Returns (libio.Ok, addrs)
// with one or more entries, or (libio.Unsupported, empty) for names that need DNS.
async lookup_host(host<string.String>) i32, std.Array {
    v<std.Array> = std.NewArray()
    perr<i32>, addr<libnet.SocketAddr> = parse_socket_addr(host.str(), host.len())
    if perr == libio.Ok {
        v.push(addr)
        return libio.Ok, v
    }
    return libio.Unsupported, v
}
