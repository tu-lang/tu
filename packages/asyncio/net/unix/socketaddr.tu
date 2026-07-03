// User-facing Unix socket-address surface for asyncio.net.unix.
//
// The address type is netio.sys.uds.SocketAddr on purpose: netio's uds layer
// (UnixListener::accept, UnixDatagram::recv_from, ...) produces that type, so
// asyncio must speak the same type to feed / return those APIs. There is no
// separate `mem UnixSocketAddr`; these free functions wrap the netio type.

use string
use netio.sys.uds as udsaddr

// Pathname of a bound / connected unix address, or "" for an unnamed
// (autobind / abstract) socket.
fn unix_addr_pathname(addr<udsaddr.SocketAddr>) string.String {
    return addr.as_pathname()
}

// True when the address carries a filesystem pathname.
fn unix_addr_is_named(addr<udsaddr.SocketAddr>) bool {
    p<string.String> = addr.as_pathname()
    return p.len() > 0
}
