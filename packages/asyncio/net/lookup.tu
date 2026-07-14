// Host resolution — mirrors tokio::net::lookup_host → addr::to_socket_addrs.
//
// Fast path: parse_ascii_bytes (tustd SocketAddr::parse_ascii). Slow path:
// strto_socket_addrs on the mandatory blocking pool (tokio spawn_blocking).

use net as libnet
use io as libio
use string
use std
use asyncio.runtime as rt
use asyncio.task

// Blocking worker output: err code + resolved address list.
mem DnsLookupResult {
    i32        err_code
    std.Array* addrs
}

// Run getaddrinfo resolution off the reactor thread.
fn blocking_strto_socket_addrs(host<string.String>) u64 {
    derr<i32>, list<std.Array> = libnet.strto_socket_addrs(host)
    out<DnsLookupResult> = new DnsLookupResult
    out.err_code = derr
    out.addrs = list
    return out.(u64)
}

// Resolve `host` ("ip:port" or hostname:port) to a SocketAddr list.
async lookup_host(host<string.String>) i32, std.Array {
    empty<std.Array> = std.NewArray()
    perr<i32>, addr<libnet.SocketAddr> = parse_socket_addr(host.str(), host.len())
    if perr == libio.Ok {
        empty.push(addr)
        return libio.Ok, empty
    }

    herr<i32>, h<rt.Handle> = rt.Handle::current()
    if herr != libio.Ok return libio.Unsupported, empty

    captured<string.String> = host
    dns_op = fn() u64 {
        return blocking_strto_socket_addrs(captured)
    }
    jh<task.JoinHandle> = h.spawn_mandatory_blocking(dns_op)
    packed<i64> = jh.await
    out<DnsLookupResult> = packed.(DnsLookupResult)
    if out.err_code != libio.Ok return out.err_code, empty
    return libio.Ok, out.addrs
}
