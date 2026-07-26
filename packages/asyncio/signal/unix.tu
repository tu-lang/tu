// Unix signal surface — SignalKind plus a stream of delivered signals.
//
// SignalStream subscribes through the runtime signal driver. The driver hands
// back an EventInfo (a sync.Notify plus a monotonic fired_count that
// SignalDriver::process bumps once per delivered siginfo); the stream tracks
// last_seen against fired_count and parks on the Notify between deliveries.
//
// Call-site naming: never export `signal*` as the first path segment after
// `sig.` — `sig.signal_…` parses as a type-assert and corrupts async frames.

use runtime
use io
use os
use asyncio.runtime as rt
use asyncio.runtime.signal as rtsig
use asyncio.sync as sync

// A Unix signal number.
mem SignalKind {
    i32 num
}

// Wrap a raw signal number.
const SignalKind::from_raw(num<i32>) SignalKind {
    return new SignalKind { num: num }
}

// The underlying signal number.
SignalKind::as_raw_value() i32 {
    return this.num
}

// Named constructors (no `signal*` prefix — avoids sig.signal_* assert trap).
fn kind_hangup() SignalKind {
    return new SignalKind { num: os.SIGHUP }
}
fn kind_interrupt() SignalKind {
    return new SignalKind { num: os.SIGINT }
}
fn kind_quit() SignalKind {
    return new SignalKind { num: os.SIGQUIT }
}
fn kind_terminate() SignalKind {
    return new SignalKind { num: os.SIGTERM }
}
fn kind_user_defined1() SignalKind {
    return new SignalKind { num: os.SIGUSR1 }
}
fn kind_user_defined2() SignalKind {
    return new SignalKind { num: os.SIGUSR2 }
}
fn kind_pipe() SignalKind {
    return new SignalKind { num: os.SIGPIPE }
}
fn kind_alarm() SignalKind {
    return new SignalKind { num: os.SIGALRM }
}
fn kind_child() SignalKind {
    return new SignalKind { num: os.SIGCHLD }
}
fn kind_window_change() SignalKind {
    return new SignalKind { num: os.SIGWINCH }
}
fn kind_io_event() SignalKind {
    return new SignalKind { num: os.SIGIO }
}

// A stream of delivered `kind` signals. last_seen is the EventInfo fired_count
// observed so far; recv resolves once the count advances past it.
// ev_bits: EventInfo* as u64 (cross-pkg mem field type crashes).
mem SignalStream {
    u64        ev_bits
    SignalKind kind
    u64        last_seen
}

// Sync Result<Signal>, not async.
// Publishes via stream_last — dual-ret (i32, SignalStream) drops mem.
LAST_SIGNAL_STREAM<SignalStream> = null

fn stream_last() SignalStream {
    return LAST_SIGNAL_STREAM
}

fn subscribe(kind<SignalKind>) i32 {
    LAST_SIGNAL_STREAM = null
    shut_err<i32> = 0x03020005 // aerr.RuntimeShutdown
    not_reg<i32>  = 0x0302000F // aerr.SignalNotRegistered
    ok_code<i32>  = io.Ok

    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return shut_err
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null return shut_err
    sh_bits<u64> = dh.sigh_bits()
    if sh_bits == 0 return shut_err

    sh<rtsig.SignalDriverHandle> = null
    sh = sh_bits
    signum<i32> = kind.as_raw_value()
    rerr<i32> = sh.register(signum)
    if rerr != 0 return rerr
    ev<rtsig.EventInfo> = rtsig.eventinfo_last()
    if ev == null return not_reg

    ev_bits<u64> = 0
    ev_bits = ev
    s<SignalStream> = new SignalStream{}
    s.ev_bits   = ev_bits
    s.kind      = kind
    // Only deliveries after subscribe are visible (per-signum fired_count).
    s.last_seen = rtsig.event_info_fired_count(ev_bits)
    LAST_SIGNAL_STREAM = s
    return ok_code
}

// Non-blocking poll: 1 and consume one delivery if a signal has fired since
// last_seen, else 0 (ready/pending as Tu i32).
SignalStream::try_recv() i32 {
    cur<u64> = rtsig.event_info_fired_count(this.ev_bits)
    if cur > this.last_seen {
        this.last_seen = cur
        return 1
    }
    return 0
}

// Leaf future for SignalStream::recv.
// Parks on EventInfo's Notify; drain calls EventInfo::fire which wakes us.
// pending_nf is Notified* as u64 (cross-pkg mem field cannot be sync.Notified*).
mem RecvFut: async {
    SignalStream* stream
    u64           pending_nf
}

RecvFut::poll(ctx) {
    s<SignalStream> = this.stream
    if s == null {
        return runtime.PollReady, io.Other
    }
    cur<u64> = rtsig.event_info_fired_count(s.ev_bits)
    if cur > s.last_seen {
        s.last_seen = cur
        this.pending_nf = 0
        return runtime.PollReady, io.Ok
    }
    if this.pending_nf == 0 {
        nb<u64> = rtsig.event_info_notify_bits(s.ev_bits)
        nf<sync.Notified> = sync.notified_from_bits(nb)
        this.pending_nf = nf.(u64)
    }
    code<i32> = sync.notified_poll_bits(this.pending_nf)
    if code == runtime.PollReady {
        this.pending_nf = 0
        cur2<u64> = rtsig.event_info_fired_count(s.ev_bits)
        if cur2 > s.last_seen {
            s.last_seen = cur2
            return runtime.PollReady, io.Ok
        }
        // Notified without a matching delivery — re-arm next poll.
        return runtime.PollPending
    }
    return runtime.PollPending
}

// Erase to runtime.Future so foreign packages can
// `.await` safely (concrete cross-pkg async mem await SIGSEGVs).
SignalStream::recv() runtime.Future {
    f<RecvFut> = new RecvFut {
        stream: this,
        pending_nf: 0
    }
    fut<runtime.Future> = f
    return fut
}
