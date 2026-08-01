// Host resolution — lookup_host. Fast path: parse_ascii_bytes. Slow path:
// spawn_blocking(strto_socket_addrs). Package-level async+await unavailable —
// expose LookupHostFut instead.

use string
use std
use io
use net
use runtime
use asyncio.runtime as rt
use asyncio.task

// Local sentinel when Handle::current fails — not library Unsupported.
NET_IO_UNSUPPORTED<i32> = 95

// Blocking worker output: err code + resolved address list.
mem DnsLookupResult {
    i32        err_code
    std.Array* addrs
}

fn blocking_strto_socket_addrs(host<string.String>) u64 {
    derr<i32>, list<std.Array> = net.strto_socket_addrs(host)
    out<DnsLookupResult> = new DnsLookupResult
    out.err_code = derr
    out.addrs = list
    return out.(u64)
}

// Leaf future for lookup_host. poll_stage: 0=start, 1=await join, 2=done.
mem LookupHostFut: async {
    string.String host
    i32 poll_stage
    task.JoinHandle* jh
    i32 err_code
    std.Array* addrs
}

LookupHostFut::poll(ctx){
    if this.poll_stage == 2 {
        return runtime.PollReady, this.err_code
    }
    if this.poll_stage == 0 {
        empty<std.Array> = std.NewArray()
        n<i32> = std.strlen(this.host.str())
        perr<i32>, bits<u64> = net.parse_ascii_bytes_bits(this.host.str(), n)
        if perr == io.Ok {
            empty.push(bits)
            this.err_code = io.Ok
            this.addrs = empty
            this.poll_stage = 2
            return runtime.PollReady, io.Ok
        }

        herr<i32>, h<rt.Handle> = rt.Handle::current()
        if herr != io.Ok {
            this.err_code = NET_IO_UNSUPPORTED
            this.addrs = empty
            this.poll_stage = 2
            return runtime.PollReady, NET_IO_UNSUPPORTED
        }

        JOB_HOST = this.host
        jh_slot<task.JoinHandle> = h.spawn_mandatory_blocking(blocking_dns_trampoline.(u64))
        this.jh = jh_slot
        this.poll_stage = 1
    }
    if this.poll_stage == 1 {
        st, val = this.jh.poll(ctx)
        if st == runtime.PollPending {
            return runtime.PollPending
        }
        out<DnsLookupResult> = val.(DnsLookupResult)
        this.err_code = out.err_code
        if out.err_code != io.Ok {
            this.addrs = std.NewArray()
        } else {
            this.addrs = out.addrs
        }
        this.poll_stage = 2
        return runtime.PollReady, this.err_code
    }
    return runtime.PollReady, this.err_code
}

// Single-slot host for the blocking trampoline (one DNS spawn at a time).
JOB_HOST<string.String> = null

fn blocking_dns_trampoline() u64 {
    return blocking_strto_socket_addrs(JOB_HOST)
}

fn lookup_host(host<string.String>) LookupHostFut {
    return new LookupHostFut {
        host: host,
        poll_stage: 0,
        jh: null,
        err_code: 0,
        addrs: null
    }
}
