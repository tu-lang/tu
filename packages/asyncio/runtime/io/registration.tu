// User-facing handle that pairs an IO source with its ScheduledIo. Hides
// the netio register/deregister dance and threads ctx + ReadyEvent through
// the readiness lifecycle.

use runtime
use netio
use netio.event as netevent
use asyncio.task
use asyncio.runtime as asyncrt

// Caller-supplied operation invoked by poll_read_io / poll_write_io once
// the resource is ready. Implementations should issue one syscall and
// surface (IO_WOULD_BLOCK, 0) when the kernel says EAGAIN; Registration
// then clears the readiness bit and re-polls.
api IoOp {
    fn try_perform() (i32, i64)
}

// Bound the readiness bits we care about for one direction.
DIRECTION_READ_MASK<i32>  = 0
DIRECTION_WRITE_MASK<i32> = 1

// Pair of (handle, shadow). handle stays opaque (`u64`) until the runtime
// root lands; shadow drives the actual readiness machinery.
mem Registration {
    u64           sched_handle  // raw bits of runtime.scheduler.Handle*; null acceptable
    IoHandle*     io_handle
    ScheduledIo*  shared
}

// Build a Registration via event.Source enroll; iosrc_bits kept for close.
const Registration::new_with_interest_and_handle(src<netevent.Source>, iosrc_bits<u64>, interest<netio.Interest>, handle<u64>, io_handle<IoHandle>) i32, Registration {
    err<i32>, sio<ScheduledIo> = io_handle.add_source(src, iosrc_bits, interest)
    if err != 0 return err, null
    // EPOLLET: data may already be buffered when the fd is added (accept then
    // peer write before the first poll). Seed READABLE from MSG_PEEK so the
    // first poll_read does not wait forever for a missed edge.
    if netio.interest_is_readable(interest) == 1 {
        if netio.iosource_peek_readable(iosrc_bits) == 1 {
            sio.set_readiness(TICK_INC, READABLE)
        }
    }
    r<Registration> = new Registration
    r.sched_handle = handle
    r.io_handle    = io_handle
    r.shared       = sio
    return 0, r
}

// Detach the source from netio and drop it from RegistrationSet. The
// Registration is unusable afterwards.
Registration::deregister(iosrc_bits<u64>) i32 {
    return this.io_handle.remove_source(iosrc_bits, this.shared)
}

// Yield when cooperative budget is exhausted (mother poll_proceed Pending+wake).
// If no waker is available, must NOT return Pending — that hangs forever with
// readiness bits set and no waiter (joint dump: READABLE + rctx=0 + ntf=0).
fn registration_coop_or_pending(ctx<u64>) i32 {
    cerr<i32>, tok<u64> = asyncrt.poll_proceed(ctx)
    if cerr == asyncrt.RT_NO_BUDGET {
        wake_ctx<u64> = task.resolve_poll_ctx(ctx)
        if wake_ctx == 0 {
            // Cannot safely yield without a waker; burn through this poll.
            return 0
        }
        task.wake_by_ctx(wake_ctx)
        return 1
    }
    return 0
}

// Poll for read readiness. Caller hands ctx so the driver can wake the task.
// Ready -> (0, ReadyEvent); Pending -> (PollPending, empty event);
// shutdown -> (OtherDriverTerminated, empty event).
//
// Coop yield MUST NOT run before observing readiness: yielding while READABLE
// is already set leaves the bit with no sio waiter (rctx=0). Under EPOLLET
// the accept backlog then stalls forever (httpserver ab listen_q hang).
Registration::poll_read_ready(ctx<u64>) i32, ReadyEvent {
    err<i32> = 0
    ev<ReadyEvent> = new ReadyEvent
    err, ev = this.shared.poll_readiness(ctx, DIR_READ)
    if err == 0 {
        return err, ev
    }
    if err != runtime.PollPending {
        return err, ev
    }
    // Truly pending (waker stored). Optional coop deferral with self-wake.
    if registration_coop_or_pending(ctx) == 1 {
        ev0<ReadyEvent> = new ReadyEvent
        return runtime.PollPending, ev0
    }
    return err, ev
}

// Mirror of poll_read_ready for the writable side.
Registration::poll_write_ready(ctx<u64>) i32, ReadyEvent {
    err<i32> = 0
    ev<ReadyEvent> = new ReadyEvent
    err, ev = this.shared.poll_readiness(ctx, DIR_WRITE)
    if err == 0 {
        return err, ev
    }
    if err != runtime.PollPending {
        return err, ev
    }
    if registration_coop_or_pending(ctx) == 1 {
        ev0<ReadyEvent> = new ReadyEvent
        return runtime.PollPending, ev0
    }
    return err, ev
}

// Clear the readiness bits captured by `event` on the ScheduledIo. tick
// matching makes this safe even when concurrent set_readiness calls have
// landed since the snapshot.
Registration::clear_readiness(event<ReadyEvent>) i32 {
    return this.shared.clear_readiness(event)
}

// Seed READABLE from a caller that already MSG_PEEK'd the fd.
Registration::reseed_readable() i32 {
    return this.shared.set_readiness(TICK_INC, READABLE)
}

// Software WRITABLE seed for readable-only epoll registrations.
Registration::seed_writable() i32 {
    return this.shared.set_readiness(TICK_INC, WRITABLE)
}

// Add EPOLLOUT to an existing readable-only registration (write WouldBlock).
Registration::enable_writable_interest() i32 {
    if this.io_handle == null || this.shared == null {
        return 1
    }
    if this.shared.iosrc_bits == 0 {
        return 1
    }
    reg<netio.Registry> = netio.registry_from_bits(this.io_handle.registry_slot)
    tok_u<u64> = this.shared.token()
    t<netio.Token> = netio.token_from_u64(tok_u)
    interest<netio.Interest> = netio.interest_merge(netio.readable_interest(), netio.writable_interest())
    return netio.registry_reregister_bits(reg, this.shared.iosrc_bits, t, interest)
}

// After WouldBlock: clear using a fresh tick snapshot so a concurrent
// set_readiness that bumped tick cannot leave sticky Ready and busy-loop
// poll_read / accept forever (httpserver MT ab hang).
Registration::clear_dir_now(dir<i32>) i32 {
    interest<netio.Interest> = netio.readable_interest()
    if dir == DIR_WRITE {
        interest = netio.writable_interest()
    }
    ev<ReadyEvent> = this.shared.ready_event(interest)
    return this.shared.clear_readiness(ev)
}

// Drive `op` against the read side: poll readiness, run op, retry on
// WouldBlock until readiness goes Pending. Returns (PollPending, 0) when
// the task should yield; (op_err, value) once op produces a real result.
Registration::poll_read_io(ctx<u64>, op<IoOp>) i32, i64 {
    err<i32> = 0
    val<i64> = 0
    err, val = registration_poll_io_dir(this, ctx, op, DIR_READ)
    return err, val
}

// Mirror of poll_read_io for the writable side.
Registration::poll_write_io(ctx<u64>, op<IoOp>) i32, i64 {
    err<i32> = 0
    val<i64> = 0
    err, val = registration_poll_io_dir(this, ctx, op, DIR_WRITE)
    return err, val
}

// Common loop body for poll_{read,write}_io. Stays a free fn so the two
// member helpers above only differ in the direction selector.
fn registration_poll_io_dir(this<Registration>, ctx<u64>, op<IoOp>, dir<i32>) i32, i64 {
    loop {
        err<i32>, ev<ReadyEvent> = this.shared.poll_readiness(ctx, dir)
        // The design registration.rs poll_io: ready!(poll_ready) then run op.
        // Ready is err==0 (not PollReady — that collides with io.Ok and
        // made callers treat readiness as failure). Pending / shutdown /
        // other errors short-circuit.
        if err == runtime.PollPending {
            if registration_coop_or_pending(ctx) == 1 {
                return runtime.PollPending, 0
            }
            return err, 0
        }
        if err != 0 {
            return err, 0
        }

        op_err<i32>, val<i64> = op.try_perform()
        if op_err == IO_WOULD_BLOCK {
            this.shared.clear_readiness(ev)
            continue
        }
        return op_err, val
    }
    return 0, 0
}

// Single-shot try_io variant: one readiness check + one op invocation.
// Returns whatever op produced; readiness is cleared on WouldBlock so the
// next poll_*_ready actually yields. Skips the retry loop above so it
// stays usable from non-async paths.
Registration::try_io(interest<netio.Interest>, op<IoOp>) i32, i64 {
    ev<ReadyEvent> = this.shared.ready_event(interest)
    if ev.ready.is_empty() return IO_WOULD_BLOCK, 0
    op_err<i32>, val<i64> = op.try_perform()
    if op_err == IO_WOULD_BLOCK {
        this.shared.clear_readiness(ev)
    }
    return op_err, val
}
