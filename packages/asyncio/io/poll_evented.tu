// User-facing wrapper that pairs a netio source with its IO Driver
// Registration. AsyncRead / AsyncWrite implementations layered on top
// of OS file descriptors (TcpStream, UdpSocket, UnixStream, pipes, ...)
// all hold a PollEvented instead of touching the runtime tree directly.

use runtime
use fmt
use netio
use netio.event as evsrc
use asyncio.runtime.io as rtio

// io.Ok without `use io` (package short-name clash with library/io).
IO_OK<i32> = 1

// inner is the netio source (TcpStream / UdpSocket / pipe / ...). reg
// owns the ScheduledIo that bridges into the IO Driver dispatch loop.
mem PollEvented {
    evsrc.Source* inner
    rtio.Registration* reg
}

// Build a PollEvented by registering `inner` with `io_handle` for the
// supplied interest. Returns (err, evented); err != 0 signals the
// underlying netio register call failed.
const PollEvented::new(inner<evsrc.Source>, interest<netio.Interest>, sched<u64>, io_handle<rtio.IoHandle>) i32, PollEvented {
    err<i32>, reg<rtio.Registration> = rtio.Registration::new_with_interest_and_handle(inner, interest, sched, io_handle)
    if err != 0 return err, null

    p<PollEvented> = new PollEvented
    p.inner = inner
    p.reg   = reg
    return 0, p
}

// Borrow the inner netio source.
PollEvented::source() evsrc.Source {
    return this.inner
}

// Poll for read readiness; ctx is the (sched, task_id) packed waker payload.
PollEvented::poll_read_ready(ctx<u64>) i32, rtio.ReadyEvent {
    err<i32>, ev<rtio.ReadyEvent> = this.reg.poll_read_ready(ctx)
    return err, ev
}

// Poll for write readiness.
PollEvented::poll_write_ready(ctx<u64>) i32, rtio.ReadyEvent {
    err<i32>, ev<rtio.ReadyEvent> = this.reg.poll_write_ready(ctx)
    return err, ev
}

// Drive `op` against the read side: poll readiness, run op, retry on
// WouldBlock until either a real result lands or readiness goes Pending.
PollEvented::poll_read_io(ctx<u64>, op<rtio.IoOp>) i32, i64 {
    err<i32>, val<i64> = this.reg.poll_read_io(ctx, op)
    return err, val
}

// Mirror of poll_read_io for the write side.
PollEvented::poll_write_io(ctx<u64>, op<rtio.IoOp>) i32, i64 {
    err<i32>, val<i64> = this.reg.poll_write_io(ctx, op)
    return err, val
}

// Single-shot try_io: one readiness check + one op invocation.
PollEvented::try_io(interest<netio.Interest>, op<rtio.IoOp>) i32, i64 {
    err<i32>, val<i64> = this.reg.try_io(interest, op)
    return err, val
}

// Detach from the IO Driver. After deregister the PollEvented must not
// be used; callers should drop their reference.
PollEvented::deregister() i32 {
    return this.reg.deregister(this.inner)
}

// Poll the requested read/write readiness on `pe`, OR-ing whatever the driver
// reports. Shared by every net *ReadyFut::poll so the loop lives in one place.
// Returns (state, err, ready): state is runtime.PollReady / runtime.PollPending;
// on PollReady, err == io.Ok means `ready` carries the set bits, otherwise err
// is a driver error code and `ready` is null.
fn poll_ready_bits(pe<PollEvented>, want_read<i32>, want_write<i32>, ctx<u64>) i32, i32, Ready {
    bits<i32> = 0
    if want_read == 1 {
        rerr<i32>, rev<rtio.ReadyEvent> = pe.poll_read_ready(ctx)
        if rerr == 0 {
            bits = bits | rev.ready.bits
        } else if rerr != runtime.PollPending {
            return runtime.PollReady, rerr, null
        }
    }
    if want_write == 1 {
        werr<i32>, wev<rtio.ReadyEvent> = pe.poll_write_ready(ctx)
        if werr == 0 {
            bits = bits | wev.ready.bits
        } else if werr != runtime.PollPending {
            return runtime.PollReady, werr, null
        }
    }
    if bits != 0 {
        return runtime.PollReady, IO_OK, Ready::from_bits(bits)
    }
    return runtime.PollPending, 0, null
}
