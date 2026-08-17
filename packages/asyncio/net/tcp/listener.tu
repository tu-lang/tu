// Async TCP listener. Wraps a netio TcpListener registered with the current
// runtime's IO driver through PollEvented: bind + readable-driven accept.
//
// accept() returns AcceptFut (sync), same pattern as TcpStream::connect →
// ConnectFut. An `async` wrapper would make one `.await` only construct the
// leaf and never poll it (call sites use accept().await for the result).
// AcceptFut::poll mirrors the design poll_accept (ready + accept + clear on
// WouldBlock) without IoOp api dispatch.

use net
use io
use runtime
use netio
use netio.event as evsrc
use netio.net.tcp as nettcp
use asyncio.io as aio
use asyncio.runtime as rt
use asyncio.runtime.io as rtio
use asyncio.error as aerr
use asyncio.task

mem TcpListener {
    aio.PollEvented* poll_ev
}

const TcpListener::bind(addr<net.SocketAddr>) (i32, TcpListener) {
    err<i32> = nettcp.TcpListener::bind(addr)
    if err != io.Ok return err, null
    inner<nettcp.TcpListener> = nettcp.tcp_listener_last()
    if inner == null return err, null
    lerr<i32>, listener<TcpListener> = TcpListener::from_netio(inner)
    return lerr, listener
}

const TcpListener::from_netio(inner<nettcp.TcpListener>) (i32, TcpListener) {
    shut_err<i32> = aerr.RuntimeShutdown
    ok_code<i32> = io.Ok
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null {
        return shut_err, null
    }
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null {
        return shut_err, null
    }
    ioh_bits<u64> = dh.ioh_bits()
    if ioh_bits == 0 {
        return shut_err, null
    }
    ioh<rtio.IoHandle> = null
    ioh = ioh_bits

    // Level-triggered accept. ET listen is functionally correct here but shows
    // multi-second accept stalls under c=100 flood (rps 14k-40k vs steady 40k);
    // LT keeps latency flat. See optimize 2026-08-05 mt-httpserver entry.
    interest<netio.Interest> = netio.readable_level_interest()
    holder<u64> = 0
    holder = inner
    src<evsrc.Source> = inner
    perr<i32>, pe<aio.PollEvented> = aio.PollEvented::new(holder, src, inner.iosrc_bits, interest, rc.sched, ioh)
    if perr != 0 {
        return perr, null
    }
    out<TcpListener> = new TcpListener
    out.poll_ev = pe
    return ok_code, out
}

TcpListener::raw_listener() nettcp.TcpListener {
    bits<u64> = this.poll_ev.source()
    l<nettcp.TcpListener> = null
    l = bits
    return l
}

// Leaf future for accept().await — the design poll_accept loop.
// done_* fields mirror ConnectFut: return values after PollPending must come
// from future fields (fresh locals/new objects in the Ready return slot were
// observed swapped/corrupt on Darwin spawn-before-accept).
mem AcceptFut: async {
    aio.PollEvented*     poll_ev
    nettcp.TcpListener*  listener
    i32                  done_err
    TcpStream*           done_stream
}

// Finish one successful accept into a TcpStream (shared by poll paths).
fn accept_finish_stream(sbits<u64>, abits<u64>) i32, TcpStream {
    if sbits == 0.(u64) {
        return io.Other, null
    }
    inner<nettcp.TcpStream> = null
    inner = sbits
    peer<net.SocketAddr> = null
    if abits != 0.(u64) {
        peer = abits
    }
    rerr2<i32>, s<TcpStream> = tcp_stream_from_netio(inner, peer)
    if rerr2 != io.Ok {
        return rerr2, null
    }
    if s == null {
        return io.Other, null
    }
    return io.Ok, s
}

AcceptFut::poll(ctx){
    would_block<i32> = io.WouldBlock
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    ok_code<i32> = io.Ok
    c<u64> = task.resolve_poll_ctx(ctx.(u64))
    // Accept-first + readiness wait (mio/tokio shape). WouldBlock must come
    // straight from accept4 — never sleep-retry in the syscall wrapper.
    loop {
        acc_err<i32>, sbits<u64>, abits<u64> = nettcp.tcp_listener_accept_bits(this.listener)
        if acc_err == ok_code {
            ferr<i32>, s<TcpStream> = accept_finish_stream(sbits, abits)
            this.done_err = ferr
            this.done_stream = s
            if ferr != ok_code {
                return ready, this.done_err, null
            }
            return ready, ok_code, this.done_stream
        }
        if acc_err != would_block {
            this.done_err = acc_err
            return ready, this.done_err, null
        }

        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(c)
        if rerr == pend {
            // Windows software epoll probes listen accept + MSG_PEEK in
            // epoll_wait; a nested driver turn here starved CT local tasks.
            return pend
        }
        if rerr != 0 {
            this.done_err = rerr
            return ready, this.done_err, null
        }
        this.poll_ev.clear_readiness(ev)
    }
}

// Sync factory (like TcpStream::connect); callers use accept().await once.
TcpListener::accept() AcceptFut {
    f<AcceptFut> = new AcceptFut
    f.poll_ev = this.poll_ev
    f.listener = this.raw_listener()
    f.done_err = 0
    f.done_stream = null
    return f
}

// Same ready/accept/clear loop as AcceptFut::poll.
TcpListener::poll_accept(ctx<u64>) i32, TcpStream {
    ok_code<i32> = io.Ok
    pend<i32> = runtime.PollPending
    ready<i32> = runtime.PollReady
    would_block<i32> = io.WouldBlock
    loop {
        listener<nettcp.TcpListener> = this.raw_listener()
        acc_err<i32>, sbits<u64>, abits<u64> = nettcp.tcp_listener_accept_bits(listener)
        if acc_err == ok_code {
            ferr<i32>, s<TcpStream> = accept_finish_stream(sbits, abits)
            if ferr != ok_code return runtime.PollError, null
            return ready, s
        }
        if acc_err != would_block {
            return runtime.PollError, null
        }

        rerr<i32>, ev<rtio.ReadyEvent> = this.poll_ev.poll_read_ready(ctx)
        if rerr == pend return pend, null
        if rerr != 0 return runtime.PollError, null
        this.poll_ev.clear_readiness(ev)
    }
}
