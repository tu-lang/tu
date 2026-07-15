// Host resolution — mirrors tokio::net::lookup_host → addr::to_socket_addrs.
//
// Fast path: parse_ascii_bytes (tustd SocketAddr::parse_ascii). Slow path:
// mother uses spawn_blocking(strto_socket_addrs); Tu leaf future polls that.
// Package-level async+await is unavailable — expose LookupHostFut instead.

use net as libnet
use io as libio
use string
use std
use runtime
use asyncio.runtime as rt
use asyncio.task

// Blocking worker output: err code + resolved address list.
mem DnsLookupResult {
    i32        err_code
    std.Array* addrs
}

fn blocking_strto_socket_addrs(host<string.String>) u64 {
    derr<i32>, list<std.Array> = libnet.strto_socket_addrs(host)
    out<DnsLookupResult> = new DnsLookupResult
    out.err_code = derr
    out.addrs = list
    return out.(u64)
}

// Leaf future for lookup_host. stage: 0=start, 1=await join, 2=done.
mem LookupHostFut: async {
    string.String host
    i32 stage
    task.JoinHandle* jh
    i32 err_code
    std.Array* addrs
}

LookupHostFut::poll(ctx){
    if this.stage == 2 {
        return runtime.PollReady, this.err_code
    }
    if this.stage == 0 {
        empty<std.Array> = std.NewArray()
        n<i32> = std.strlen(this.host.str())
        perr<i32>, addr<libnet.SocketAddr> = parse_socket_addr(this.host.str(), n)
        if perr == libio.Ok {
            empty.push(addr)
            this.err_code = libio.Ok
            this.addrs = empty
            this.stage = 2
            return runtime.PollReady, libio.Ok
        }

        herr<i32>, h<rt.Handle> = rt.Handle::current()
        if herr != libio.Ok {
            this.err_code = libio.Unsupported
            this.addrs = empty
            this.stage = 2
            return runtime.PollReady, libio.Unsupported
        }

        // Mother: spawn_blocking(|| to_socket_addrs(host)).
        // Pass host via BlockingDnsJob held in the JoinHandle path:
        // u64 op is a trampoline that reads JOB_HOST (set only for this spawn).
        JOB_HOST = this.host
        jh<task.JoinHandle> = h.spawn_mandatory_blocking(blocking_dns_trampoline.(u64))
        this.jh = jh
        this.stage = 1
    }
    if this.stage == 1 {
        st, val = this.jh.poll(ctx)
        if st == runtime.PollPending {
            return runtime.PollPending
        }
        out<DnsLookupResult> = val.(DnsLookupResult)
        this.err_code = out.err_code
        if out.err_code != libio.Ok {
            this.addrs = std.NewArray()
        } else {
            this.addrs = out.addrs
        }
        this.stage = 2
        return runtime.PollReady, this.err_code
    }
    return runtime.PollReady, this.err_code
}

// Single-slot host for the blocking trampoline (serializer: one DNS spawn at a time).
JOB_HOST<string.String> = null

fn blocking_dns_trampoline() u64 {
    return blocking_strto_socket_addrs(JOB_HOST)
}

// User entry matching tokio::net::lookup_host — returns a leaf future.
fn lookup_host(host<string.String>) LookupHostFut {
    return new LookupHostFut {
        host: host,
        stage: 0,
        jh: null,
        err_code: 0,
        addrs: null
    }
}
