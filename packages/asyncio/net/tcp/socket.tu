// TCP socket-option setters used by TcpStream / TcpListener. Thin wrappers over
// sys.setsockopt keyed by raw fd.
//
// Note: SO_REUSEADDR / SO_KEEPALIVE / TCP_NODELAY / IPPROTO_TCP are not defined
// in library/sys (only SOL_SOCKET / SO_ERROR are), so their Linux x86_64 values
// are declared here.

use sys
use io

// Socket-option level / name constants (Linux x86_64).
SO_REUSEADDR<i32> = 2
SO_KEEPALIVE<i32> = 9
IPPROTO_TCP<i32>  = 6
TCP_NODELAY<i32>  = 1

// Wrap a raw fd as a sys.Socket for setsockopt (mirrors library/net's fromrawfd).
fn fd_to_socket(fd<i32>) sys.Socket {
    return new sys.Socket { fd: sys.FileDesc::from_raw_fd(fd) }
}

// Toggle SO_REUSEADDR. on != 0 enables address reuse. Returns io.Ok / error.
fn tcp_set_reuseaddr(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, sys.SOL_SOCKET, SO_REUSEADDR, &val, sizeof(i32))
}

// Toggle TCP_NODELAY (disable Nagle). on != 0 disables buffering.
fn tcp_set_nodelay(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, IPPROTO_TCP, TCP_NODELAY, &val, sizeof(i32))
}

// Enable/disable SO_KEEPALIVE. secs > 0 turns keepalive on; per-idle tuning
// (TCP_KEEPIDLE etc.) is omitted since library/sys lacks those constants.
fn tcp_set_keepalive(fd<i32>, secs<i32>) i32 {
    val<i32> = 0
    if secs > 0 val = 1
    sock<sys.Socket> = fd_to_socket(fd)
    return sys.setsockopt(sock, sys.SOL_SOCKET, SO_KEEPALIVE, &val, sizeof(i32))
}
