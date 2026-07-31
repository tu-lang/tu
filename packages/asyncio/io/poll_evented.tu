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

// holder_bits: concrete netio socket/listener object (TcpStream*, …) as u64.
// iosrc_bits: IoSource* as u64 used for epoll register (bypasses Source api).
// reg owns the ScheduledIo that bridges into the IO Driver dispatch loop.
mem PollEvented {
    u64                holder_bits
    u64                iosrc_bits
    rtio.Registration* reg
}

// Build a PollEvented by registering `iosrc_bits` with `io_handle`.
// holder_bits is returned by source() for accept/read/write ops.
const PollEvented::new(holder_bits<u64>, iosrc_bits<u64>, interest<netio.Interest>, sched<u64>, io_handle<rtio.IoHandle>) i32, PollEvented {
    err<i32>, reg<rtio.Registration> = rtio.Registration::new_with_interest_and_handle(iosrc_bits, interest, sched, io_handle)
    if err != 0 return err, null

    p<PollEvented> = new PollEvented
    p.holder_bits = holder_bits
    p.iosrc_bits  = iosrc_bits
    p.reg         = reg
    return 0, p
}

// Borrow the inner netio source object bits (cast at call site to concrete type).
PollEvented::source() u64 {
    return this.holder_bits
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

// Clear readiness bits from a prior poll_*_ready snapshot.
PollEvented::clear_readiness(event<rtio.ReadyEvent>) i32 {
    return this.reg.clear_readiness(event)
}

// Single-shot try_io: one readiness check + one op invocation.
PollEvented::try_io(interest<netio.Interest>, op<rtio.IoOp>) i32, i64 {
    err<i32>, val<i64> = this.reg.try_io(interest, op)
    return err, val
}

// Detach from the IO Driver. After deregister the PollEvented must not
// be used; callers should drop their reference.
PollEvented::deregister() i32 {
    if this.reg == null {
        return 0
    }
    err<i32> = this.reg.deregister(this.iosrc_bits)
    this.reg = null
    return err
}

// Deregister from the driver and close the OS fd (Tu has no Drop).
PollEvented::close() i32 {
    bits<u64> = this.iosrc_bits
    err<i32> = this.deregister()
    if bits != 0 {
        netio.iosource_close_fd(bits)
        this.iosrc_bits = 0
        this.holder_bits = 0
    }
    return err
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
