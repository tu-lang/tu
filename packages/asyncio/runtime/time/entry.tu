// Per-Sleep state cell + wheel-side timer entry. StateCell is the atomic
// owner of the deadline and the join-style waker; TimerShared/TimerEntry
// chain entries on a wheel slot.

use std.atomic
use runtime
use asyncio.sync as libsync
use asyncio.util

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS64_OK<i64> = 1

// Sentinels packed into StateCell.state.
//   STATE_DEREGISTERED — entry removed from the wheel; subsequent polls bail.
//   STATE_PENDING_FIRE — wheel observed deadline; result is being delivered.
//   anything else      — milliseconds-since-epoch deadline (< MAX_SAFE_MILLIS).
STATE_DEREGISTERED<u64> = 0xffffffffffffffff
STATE_PENDING_FIRE<u64> = 0xfffffffffffffffe
MAX_SAFE_MILLIS<u64>    = 0xfffffffffffffffd

// Result codes surfaced via StateCell::poll.
RESULT_OK<i32>          = 0
RESULT_CANCELLED<i32>   = 1
RESULT_FIRED<i32>       = 2

// Atomic deadline word + waker slot for one Sleep.
// Field is when_word (not `state`) to avoid asmgen `.state` traps.
mem StateCell {
    u64                 when_word // atomic; deadline_ms or sentinel
    i32                 result    // last delivered result code
    runtime.MutexInter* waker_lock
    u64                 waker_bits // AtomicWaker* bits
}

// Build a StateCell owning a fresh AtomicWaker.
const StateCell::new() StateCell {
    s<StateCell> = new StateCell
    s.when_word = STATE_DEREGISTERED
    s.result = RESULT_OK
    s.waker_lock = new runtime.MutexInter
    s.waker_lock.init()
    s.waker_bits = libsync.atomic_waker_new_raw()
    return s
}

// Atomic snapshot of the deadline word.
StateCell::load_state() u64 {
    return atomic.load64(&this.when_word)
}

// True when the cell is no longer scheduled (deregister won the race).
StateCell::is_deregistered() i32 {
    if this.load_state() == STATE_DEREGISTERED return 1
    return 0
}

// True when the wheel has fired the timer (result is ready to deliver).
StateCell::is_pending_fire() i32 {
    if this.load_state() == STATE_PENDING_FIRE return 1
    return 0
}

// Mark the entry as ready to deliver. The wheel calls this just before
// firing the waker. Returns 0 on success, RESULT_CANCELLED when state was
// already DEREGISTERED.
StateCell::mark_pending(not_after<u64>) i32 {
    loop {
        cur<u64> = atomic.load64(&this.when_word)
        if cur == STATE_DEREGISTERED return RESULT_CANCELLED
        if cur == STATE_PENDING_FIRE return RESULT_OK
        if cur > not_after return RESULT_CANCELLED
        if atomic.cas64(&this.when_word, cur.(i64), STATE_PENDING_FIRE.(i64)) == CAS64_OK {
            return RESULT_OK
        }
    }
    return RESULT_OK
}

// Store deadline under driver lock.
// Fresh cells start at STATE_DEREGISTERED; unconditional store is enough.
// std_atomic_store64 only consumes (addr, value) — the 2nd arg is written.
// Passing (addr, old, new) stored `old` (DEREGISTERED) and ignored `new`,
// so every Sleep::poll saw CANCELLED immediately.
StateCell::arm(deadline_ms<u64>) i32 {
    if deadline_ms >= MAX_SAFE_MILLIS return RESULT_CANCELLED
    old<u64> = atomic.load64(&this.when_word)
    if old == STATE_PENDING_FIRE return RESULT_OK
    atomic.store64(&this.when_word, deadline_ms)
    return RESULT_OK
}

// Permanently unwire the entry. Wheel callbacks become no-ops afterwards.
StateCell::deregister(){
    loop {
        cur<u64> = atomic.load64(&this.when_word)
        if cur == STATE_DEREGISTERED { return }
        if atomic.cas64(&this.when_word, cur.(i64), STATE_DEREGISTERED.(i64)) == CAS64_OK { return }
    }
}

// Poll the cell. Returns (RESULT_*, fired) where fired==1 means the wheel
// already produced the result. Registers the waker, then reads state.
StateCell::poll(ctx<u64>) (i32, i32) {
    // The design registers the waker first so a racing fire observes it.
    this.waker_lock.lock()
    libsync.atomic_waker_register_raw(this.waker_bits, ctx)
    this.waker_lock.unlock()

    cur<u64> = atomic.load64(&this.when_word)
    if cur == STATE_DEREGISTERED return RESULT_CANCELLED, 0
    if cur == STATE_PENDING_FIRE  return RESULT_FIRED, 1
    return RESULT_OK, 0
}

// Hand the cell its waker so the wheel can pull ctx during fire().
StateCell::take_waker_ctx() u64 {
    return libsync.atomic_waker_wake_raw(this.waker_bits)
}

// Wheel-side handle. Sleeps reach the wheel through TimerShared.
// `pointers` MUST be the first field (offset 0): EntryList casts Pointers*
// to TimerShared* the same way util.LinkedList does (see linked_list.tu).
// Field is `scell` — `.state` / `.cell` are type-assert traps even in methods.
mem TimerShared {
    util.Pointers pointers      // intrusive prev/next — offset 0 required
    StateCell*    scell
    u64           cached_when   // last deadline_ms seen by the wheel
}

// Build a wheel-side handle for cell.
const TimerShared::new(cell<StateCell>) TimerShared {
    s<TimerShared> = new TimerShared
    s.pointers.prev = null
    s.pointers.next = null
    s.scell         = cell
    s.cached_when   = STATE_DEREGISTERED
    return s
}

// Read the StateCell*; callers must use this helper (not `.scell` cross-expr).
TimerShared::get_cell() StateCell {
    return this.scell
}


// Sleep-side counterpart. Sleep::poll funnels into TimerEntry::poll_elapsed.
mem TimerEntry {
    TimerShared* shared
    u64          deadline_ms
    i32          registered    // monotonic 0 -> 1 once linked into a wheel
}

// Allocate a TimerEntry with the supplied deadline (not yet linked).
const TimerEntry::new(deadline_ms<u64>) TimerEntry {
    e<TimerEntry> = new TimerEntry
    cell<StateCell> = StateCell::new()
    // Arm the cell with the deadline.
    cell.arm(deadline_ms)
    e.shared      = TimerShared::new(cell)
    e.deadline_ms = deadline_ms
    e.registered  = 0
    return e
}

// Cross-pkg factory bridge. `rttime.TimerEntry::new` also works when typed.
fn timer_entry_new(deadline_ms<u64>) TimerEntry {
    return TimerEntry::new(deadline_ms)
}

// Cross-pkg poll: entry held as u64 bits outside this package.
fn timer_entry_poll_elapsed_bits(entry_bits<u64>, ctx<u64>) i32 {
    e<TimerEntry> = entry_bits
    return e.poll_elapsed(ctx)
}

// Mark deregistered so the wheel does not fire after Drop.
TimerEntry::cancel(){
    s<StateCell> = this.shared.get_cell()
    s.deregister()
}

// True once the deadline has fired.
TimerEntry::is_elapsed() i32 {
    s<StateCell> = this.shared.get_cell()
    return s.is_pending_fire()
}

// Sleep-future hand-off: returns RESULT_FIRED when the entry has elapsed,
// RESULT_OK + 0 to keep waiting (waker armed), RESULT_CANCELLED when the
// entry has been deregistered.
TimerEntry::poll_elapsed(ctx<u64>) i32 {
    s<StateCell> = this.shared.get_cell()
    code<i32>, fired<i32> = s.poll(ctx)
    if fired != 0 return RESULT_FIRED
    return code
}

