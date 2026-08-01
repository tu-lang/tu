// Runtime-side Sleep leaf. Holds a traced TimerEntry* so GC cannot free
// the entry while the future is live.
//
// Registration uses TimeHandle::register; the active handle is published
// by builder_block_on via sleep_set_handle.

use runtime
use io
use asyncio.task as task

SLEEP_RESULT_OK<i32>        = 0
SLEEP_RESULT_CANCELLED<i32> = 1
SLEEP_RESULT_FIRED<i32>     = 2

// TimeHandle published by runtime builder_block_on (null if none).
// Sleep::poll registers through this slot so this package need not import
// asyncio.runtime (avoids import cycles). Published once at block_on enter.
ACTIVE_SLEEP_HANDLE<TimeHandle> = null

// Publish a non-null TimeHandle. Never clear with null — factories that
// probe context before enter would otherwise wipe the builder publish.
fn sleep_set_handle(th<TimeHandle>) {
    if th == null { return }
    ACTIVE_SLEEP_HANDLE = th
}

// Compat: publish from raw bits (builder may still pass DriverHandle bits).
fn sleep_set_handle_bits(bits<u64>) {
    if bits == 0 { return }
    th<TimeHandle> = bits
    sleep_set_handle(th)
}

// Read the published handle (for deadline math in asyncio.time).
fn sleep_active_handle() TimeHandle {
    return ACTIVE_SLEEP_HANDLE
}

// Compat bits view of the published handle.
fn sleep_active_handle_bits() u64 {
    th<TimeHandle> = ACTIVE_SLEEP_HANDLE
    if th == null return 0
    return th.(u64)
}

mem Sleep: async {
    TimerEntry* entry
    u64         duration_ms  // non-zero: resolve absolute deadline on first poll
    i32         registered
}

// Register once, then poll_elapsed until fired.
// Duration-based sleeps compute now+duration here so eager construction
// before block_on (or slow MT worker start) cannot treat relative ms as
// absolute wheel deadlines and fire both arms of select at once.
Sleep::poll(ctx){
    if this.registered == 0 {
        th<TimeHandle> = ACTIVE_SLEEP_HANDLE
        if th != null {
            if this.duration_ms != 0 {
                now_ms<u64> = time_handle_now_ms(th)
                dl<u64> = now_ms + this.duration_ms
                this.entry.deadline_ms = dl
                cell<StateCell> = this.entry.shared.get_cell()
                cell.arm(dl)
                this.duration_ms = 0
            }
            th.register(this.entry)
        } else if this.duration_ms != 0 {
            // No handle yet: arm relative from 0 (rare probe path).
            dl0<u64> = this.duration_ms
            this.entry.deadline_ms = dl0
            cell0<StateCell> = this.entry.shared.get_cell()
            cell0.arm(dl0)
            this.duration_ms = 0
        }
        this.registered = 1
    }
    packed<u64> = task.resolve_poll_ctx(ctx.(u64))
    code<i32> = this.entry.poll_elapsed(packed)
    if code == SLEEP_RESULT_FIRED return runtime.PollReady, io.Ok
    if code == SLEEP_RESULT_CANCELLED return runtime.PollReady, sleep_timer_shutdown()
    return runtime.PollPending
}

fn sleep_timer_shutdown() i32 {
    return 0x03020010
}

// Absolute-deadline sleep (sleep_until / interval).
fn sleep_new(deadline_ms<u64>) Sleep {
    e<TimerEntry> = TimerEntry::new(deadline_ms)
    return new Sleep { entry: e, duration_ms: 0, registered: 0 }
}

// Relative sleep: deadline = now + duration_ms resolved on first poll.
fn sleep_new_duration(duration_ms<u64>) Sleep {
    e<TimerEntry> = TimerEntry::new(0)
    return new Sleep { entry: e, duration_ms: duration_ms, registered: 0 }
}
