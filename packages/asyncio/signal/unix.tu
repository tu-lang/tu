// tokio::signal::unix — SignalKind plus a stream of delivered signals.
//
// SignalStream subscribes through the runtime signal driver. The driver hands
// back an EventInfo (a sync.Notify plus a monotonic fired_count that
// SignalDriver::process bumps once per delivered siginfo); the stream tracks
// last_seen against fired_count and parks on the Notify between deliveries.
//
// Design note (task 18.2): the spec models SignalStream over a
// sync.broadcast.Receiver, but the registry exposes EventInfo, so the stream
// is built on that instead. `class` -> `mem` per library-static-only.

use runtime
use io
use os
use asyncio.runtime as rt
use asyncio.runtime.signal as rtsig
use asyncio.error as aerr
use asyncio.sync

// A Unix signal number (tokio::signal::unix::SignalKind).
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

// Named constructors for the signals tokio exposes on Unix.
fn SignalKind_hangup() SignalKind {
    return new SignalKind { num: os.SIGHUP }
}
fn SignalKind_interrupt() SignalKind {
    return new SignalKind { num: os.SIGINT }
}
fn SignalKind_quit() SignalKind {
    return new SignalKind { num: os.SIGQUIT }
}
fn SignalKind_terminate() SignalKind {
    return new SignalKind { num: os.SIGTERM }
}
fn SignalKind_user_defined1() SignalKind {
    return new SignalKind { num: os.SIGUSR1 }
}
fn SignalKind_user_defined2() SignalKind {
    return new SignalKind { num: os.SIGUSR2 }
}
fn SignalKind_pipe() SignalKind {
    return new SignalKind { num: os.SIGPIPE }
}
fn SignalKind_alarm() SignalKind {
    return new SignalKind { num: os.SIGALRM }
}
fn SignalKind_child() SignalKind {
    return new SignalKind { num: os.SIGCHLD }
}
fn SignalKind_window_change() SignalKind {
    return new SignalKind { num: os.SIGWINCH }
}
fn SignalKind_io_event() SignalKind {
    return new SignalKind { num: os.SIGIO }
}

// A stream of delivered `kind` signals. last_seen is the EventInfo fired_count
// observed so far; recv resolves once the count advances past it.
mem SignalStream {
    rtsig.EventInfo* ev
    SignalKind       kind
    u64              last_seen
}

// Subscribe to `kind` on the current runtime's signal driver. Returns
// (io.Ok, stream) or (err, null): RuntimeShutdown when no signal driver is
// active, or the driver register error (SignalNotRegistered / signalfd fail).
// last_seen starts at the current count so only signals delivered after this
// call are surfaced.
async signal(kind<SignalKind>) i32, SignalStream {
    rc<rt.RuntimeContext> = rt.current_context()
    if rc == null return aerr.RuntimeShutdown, null
    dh<rt.DriverHandle> = rt.context_driver_handle(rc)
    if dh == null || dh.signal_handle == null return aerr.RuntimeShutdown, null

    sh<rtsig.SignalDriverHandle> = dh.signal_handle
    rerr<i32>, ev<rtsig.EventInfo> = sh.register(kind.num)
    if rerr != 0 return rerr, null
    if ev == null return aerr.SignalNotRegistered, null

    s<SignalStream> = new SignalStream
    s.ev        = ev
    s.kind      = kind
    s.last_seen = ev.fired_count_snapshot()
    return io.Ok, s
}

// Non-blocking poll: returns true and consumes one delivery if a signal has
// fired since last_seen, else false. Useful to assert a signal did NOT arrive.
SignalStream::try_recv() bool {
    cur<u64> = this.ev.fired_count_snapshot()
    if cur > this.last_seen {
        this.last_seen = cur
        return true
    }
    return false
}

// Await the next delivered signal. Returns io.Ok once fired_count advances.
// V1 note: a fire landing in the narrow window between the count check and
// parking on Notify can be missed; the signal-driver integration is WIP.
async SignalStream::recv() i32 {
    loop {
        cur<u64> = this.ev.fired_count_snapshot()
        if cur > this.last_seen {
            this.last_seen = cur
            return io.Ok
        }
        fut<Notified> = notified_from_bits(this.ev.notify_bits)
        code<i32> = fut.await
        if code != 0 return code
    }
    return io.Ok
}
