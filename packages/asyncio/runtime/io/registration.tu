// User-facing handle that pairs an IO source with its ScheduledIo. Hides
// the netio register/deregister dance and threads ctx + ReadyEvent through
// the readiness lifecycle.

use runtime
use netio
use netio.event as netevent

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

// Build a Registration: allocate the ScheduledIo and register the source
// with netio. On failure leaves nothing behind.
// Build a Registration: allocate the ScheduledIo and register the IoSource
// bits with netio. On failure leaves nothing behind.
// iosrc_bits: IoSource* as u64 (avoids event.Source api dispatch segfault).
const Registration::new_with_interest_and_handle(iosrc_bits<u64>, interest<netio.Interest>, handle<u64>, io_handle<IoHandle>) i32, Registration {
    err<i32>, sio<ScheduledIo> = io_handle.add_source(iosrc_bits, interest)
    if err != 0 return err, null
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

// Poll for read readiness. Caller hands ctx so the driver can wake the task.
// PollReady -> (0, ReadyEvent); PollPending -> (PollPending, empty event);
// shutdown -> (OtherDriverTerminated, empty event).
Registration::poll_read_ready(ctx<u64>) i32, ReadyEvent {
    err<i32> = 0
    ev<ReadyEvent> = new ReadyEvent
    err, ev = this.shared.poll_readiness(ctx, DIR_READ)
    return err, ev
}

// Mirror of poll_read_ready for the writable side.
Registration::poll_write_ready(ctx<u64>) i32, ReadyEvent {
    err<i32> = 0
    ev<ReadyEvent> = new ReadyEvent
    err, ev = this.shared.poll_readiness(ctx, DIR_WRITE)
    return err, ev
}

// Clear the readiness bits captured by `event` on the ScheduledIo. tick
// matching makes this safe even when concurrent set_readiness calls have
// landed since the snapshot.
Registration::clear_readiness(event<ReadyEvent>) i32 {
    return this.shared.clear_readiness(event)
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
        // Mother registration.rs poll_io: ready!(poll_ready) then run op.
        // poll_readiness returns PollReady (=1) on hit — only Pending /
        // shutdown short-circuit; Ready falls through to the syscall.
        if err != runtime.PollReady {
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

