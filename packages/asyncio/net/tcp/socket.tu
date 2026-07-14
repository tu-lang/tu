// TCP socket-option setters used by TcpStream / TcpListener. Thin wrappers over
// sys.setsockopt keyed by raw fd. Option constants live in library/sys.

use sys
use io

// Toggle SO_REUSEADDR. on != 0 enables address reuse. Returns io.Ok / error.
fn tcp_set_reuseaddr(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    err<i32>, _ = sys.cvt(sys.setsockopt(fd, sys.SOL_SOCKET, sys.SO_REUSEADDR, val.(u64), 4))
    return err
}

// Toggle TCP_NODELAY (disable Nagle). on != 0 disables buffering.
fn tcp_set_nodelay(fd<i32>, on<i32>) i32 {
    val<i32> = 0
    if on != 0 val = 1
    err<i32>, _ = sys.cvt(sys.setsockopt(fd, sys.IPPROTO_TCP, sys.TCP_NODELAY, val.(u64), 4))
    return err
}

// Enable/disable SO_KEEPALIVE. secs > 0 turns keepalive on; per-idle tuning
// (TCP_KEEPIDLE etc.) is omitted since library/sys lacks those constants.
fn tcp_set_keepalive(fd<i32>, secs<i32>) i32 {
    val<i32> = 0
    if secs > 0 val = 1
    err<i32>, _ = sys.cvt(sys.setsockopt(fd, sys.SOL_SOCKET, sys.SO_KEEPALIVE, val.(u64), 4))
    return err
}
