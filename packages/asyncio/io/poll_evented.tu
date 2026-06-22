// User-facing wrapper that pairs a netio source with its IO Driver
// Registration. AsyncRead / AsyncWrite implementations layered on top
// of OS file descriptors (TcpStream, UdpSocket, UnixStream, pipes, ...)
// all hold a PollEvented instead of touching the runtime tree directly.

use runtime
use netio
use asyncio.runtime as rt

// inner is the netio source (TcpStream / UdpSocket / pipe / ...). reg
// owns the ScheduledIo that bridges into the IO Driver dispatch loop.
mem PollEvented {
    netio.event.Source* inner
    rt.io.Registration* reg
}

// Build a PollEvented by registering `inner` with `io_handle` for the
// supplied interest. Returns (err, evented); err != 0 signals the
// underlying netio register call failed.
const PollEvented::new(inner<netio.event.Source>, interest<netio.Interest>, sched<u64>, io_handle<rt.io.IoHandle>) (i32, PollEvented) {
    err<i32>, reg<rt.io.Registration> = rt.io.Registration::new_with_interest_and_handle(inner, interest, sched, io_handle)
    if err != 0 return err, null

    p<PollEvented> = new PollEvented
    p.inner = inner
    p.reg   = reg
    return 0, p
}

// Borrow the inner netio source.
PollEvented::source() netio.event.Source {
    return this.inner
}

// Poll for read readiness; ctx is the (sched, task_id) packed waker payload.
PollEvented::poll_read_ready(ctx<u64>) (i32, rt.io.ReadyEvent) {
    return this.reg.poll_read_ready(ctx)
}

// Poll for write readiness.
PollEvented::poll_write_ready(ctx<u64>) (i32, rt.io.ReadyEvent) {
    return this.reg.poll_write_ready(ctx)
}

// Drive `op` against the read side: poll readiness, run op, retry on
// WouldBlock until either a real result lands or readiness goes Pending.
PollEvented::poll_read_io(ctx<u64>, op<rt.io.IoOp>) (i32, i64) {
    return this.reg.poll_read_io(ctx, op)
}

// Mirror of poll_read_io for the write side.
PollEvented::poll_write_io(ctx<u64>, op<rt.io.IoOp>) (i32, i64) {
    return this.reg.poll_write_io(ctx, op)
}

// Single-shot try_io: one readiness check + one op invocation.
PollEvented::try_io(interest<netio.Interest>, op<rt.io.IoOp>) (i32, i64) {
    return this.reg.try_io(interest, op)
}

// Detach from the IO Driver. After deregister the PollEvented must not
// be used; callers should drop their reference.
PollEvented::deregister() i32 {
    return this.reg.deregister(this.inner)
}
