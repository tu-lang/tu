// Runtime-side Sleep leaf. Holds a traced TimerEntry* so GC cannot free
// the entry while the future is live. Mother: tokio::time::Sleep entry half.
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
// asyncio.runtime (avoids import cycles). Mother: Handle lives on context;
// we publish once at block_on enter.
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
    i32         registered
}

// Mother: Sleep::poll — register once, then poll_elapsed until fired.
Sleep::poll(ctx){
    if this.registered == 0 {
        th_bits<u64> = ACTIVE_SLEEP_HANDLE_BITS
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

fn sleep_new(deadline_ms<u64>) Sleep {
    e<TimerEntry> = TimerEntry::new(deadline_ms)
    return new Sleep { entry: e, registered: 0 }
}
