// Runtime-side Sleep leaf. Holds a traced TimerEntry* so GC cannot free
// the entry while the future is live.
//
// Registration uses time_handle_register_bits; the active handle bits are
// published by builder_block_on via sleep_set_handle_bits.

use runtime
use io
use asyncio.task as task

SLEEP_RESULT_OK<i32>        = 0
SLEEP_RESULT_CANCELLED<i32> = 1
SLEEP_RESULT_FIRED<i32>     = 2

// TimeHandle bits published by runtime builder_block_on (0 if none).
// Sleep::poll registers through this slot so this package need not import
// asyncio.runtime (avoids import cycles). Published once at block_on enter.
ACTIVE_SLEEP_HANDLE_BITS<u64> = 0

// Publish a non-zero TimeHandle. Never clear with 0 — factories that probe
// context before enter would otherwise wipe the builder publish.
fn sleep_set_handle_bits(bits<u64>) {
    if bits == 0 { return }
    ACTIVE_SLEEP_HANDLE_BITS = bits
}

// Read the published handle bits (for deadline math in asyncio.time).
fn sleep_active_handle_bits() u64 {
    return ACTIVE_SLEEP_HANDLE_BITS
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
        th_bits<u64> = ACTIVE_SLEEP_HANDLE_BITS
        if this.duration_ms != 0 {
            now_ms<u64> = 0
            if th_bits != 0 {
                now_ms = time_handle_now_ms_bits(th_bits)
            }
            dl<u64> = now_ms + this.duration_ms
            this.entry.deadline_ms = dl
            cell<StateCell> = this.entry.shared.get_cell()
            cell.arm(dl)
            this.duration_ms = 0
        }
        if th_bits != 0 {
            e_bits<u64> = 0
            e_bits = this.entry
            time_handle_register_bits(th_bits, e_bits)
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
