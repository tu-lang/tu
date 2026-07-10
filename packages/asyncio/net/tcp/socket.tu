// TCP socket-option setters used by TcpStream / TcpListener. Thin wrappers over
// sys.setsockopt keyed by raw fd. Option constants live in library/sys.

use sys
use io

// Wrap a raw fd as a sys.Socket for setsockopt (mirrors library/net's fromrawfd).
fn fd_to_socket(fd<i32>) sys.Socket {
    return new sys.Socket { fd: sys.FileDesc::from_raw_fd(fd) }
}

// Toggle SO_REUSEADDR. on != 0 enables address reuse. Returns io.Ok / error.
fn tcp_set_reuseaddr(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, sys.SOL_SOCKET, sys.SO_REUSEADDR, &val, 4)
}

// Toggle TCP_NODELAY (disable Nagle). on != 0 disables buffering.
fn tcp_set_nodelay(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, sys.IPPROTO_TCP, sys.TCP_NODELAY, &val, 4)
}

// Enable/disable SO_KEEPALIVE. secs > 0 turns keepalive on; per-idle tuning
// (TCP_KEEPIDLE etc.) is omitted since library/sys lacks those constants.
fn tcp_set_keepalive(fd<i32>, secs<i32>) i32 {
    val<i32> = 0
    if secs > 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, sys.SOL_SOCKET, sys.SO_KEEPALIVE, &val, 4)
}
