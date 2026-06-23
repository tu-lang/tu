// Per-Sleep state cell + wheel-side timer entry. StateCell is the atomic
// owner of the deadline and the join-style waker; TimerShared/TimerEntry
// chain entries on a wheel slot.

use std.atomic
use runtime
use sync

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

// Atomic state + waker slot for one Sleep. waker is registered on first
// poll and re-armed if the task is moved between threads.
mem StateCell {
    u64                state    // atomic; deadline_ms or sentinel
    i32                result   // last delivered result code
    runtime.MutexInter waker_lock
    sync.AtomicWaker*  waker
}

// Build a StateCell owning a fresh AtomicWaker.
const StateCell::new() StateCell {
    s<StateCell> = new StateCell
    s.state  = STATE_DEREGISTERED
    s.result = RESULT_OK
    s.waker_lock.init()
    s.waker  = sync.AtomicWaker::new()
    return s
}

// Atomic snapshot of the deadline word.
StateCell::load_state() u64 {
    return atomic.load64(&this.state)
}

// True when the cell is no longer scheduled (deregister won the race).
StateCell::is_deregistered() bool {
    if this.load_state() == STATE_DEREGISTERED return true
    return false
}

// True when the wheel has fired the timer (result is ready to deliver).
StateCell::is_pending_fire() bool {
    if this.load_state() == STATE_PENDING_FIRE return true
    return false
}

// Mark the entry as ready to deliver. The wheel calls this just before
// firing the waker. Returns 0 on success, RESULT_CANCELLED when state was
// already DEREGISTERED.
StateCell::mark_pending(not_after<u64>) i32 {
    addr<u64*> = &this.state
    loop {
        cur<u64> = atomic.load64(addr)
        if cur == STATE_DEREGISTERED return RESULT_CANCELLED
        if cur == STATE_PENDING_FIRE return RESULT_OK
        if cur > not_after return RESULT_CANCELLED
        if atomic.cas64(addr.(i64*), cur.(i64), STATE_PENDING_FIRE.(i64)) != 0 {
            return RESULT_OK
        }
    }
    return RESULT_OK
}

// Set the deadline. Caller's responsibility to make sure the entry is in
// the wheel for that deadline. Returns 0 on success, RESULT_CANCELLED if
// the cell has been deregistered.
StateCell::arm(deadline_ms<u64>) i32 {
    if deadline_ms >= MAX_SAFE_MILLIS return RESULT_CANCELLED
    addr<u64*> = &this.state
    loop {
        cur<u64> = atomic.load64(addr)
        if cur == STATE_DEREGISTERED return RESULT_CANCELLED
        if atomic.cas64(addr.(i64*), cur.(i64), deadline_ms.(i64)) != 0 return RESULT_OK
    }
    return RESULT_OK
}

// Permanently unwire the entry. Wheel callbacks become no-ops afterwards.
StateCell::deregister(){
    addr<u64*> = &this.state
    loop {
        cur<u64> = atomic.load64(addr)
        if cur == STATE_DEREGISTERED return
        if atomic.cas64(addr.(i64*), cur.(i64), STATE_DEREGISTERED.(i64)) != 0 return
    }
}

// Poll the cell. Returns (RESULT_*, fired) where fired==1 means the wheel
// already produced the result.
StateCell::poll(ctx<u64>) (i32, i32) {
    cur<u64> = atomic.load64(&this.state)
    if cur == STATE_DEREGISTERED return RESULT_CANCELLED, 0
    if cur == STATE_PENDING_FIRE  return RESULT_FIRED, 1

    // Arm the waker under waker_lock so concurrent fire() observes a
    // stable ctx slot. AtomicWaker handles wake/register races itself.
    this.waker_lock.lock()
    this.waker.register_by_ref(ctx)
    this.waker_lock.unlock()
    return RESULT_OK, 0
}

// Hand the cell its waker so the wheel can pull ctx during fire().
StateCell::take_waker_ctx() u64 {
    return this.waker.wake()
}

// Wheel-side handle. Sleeps reach the wheel through TimerShared, which is
// embedded in TimerEntry; cached_when speeds up cancellation by skipping
// the slot scan when the deadline has not changed since insert.
mem TimerShared {
    StateCell* state
    Pointers   pointers      // intrusive prev/next on a wheel slot list
    u64        cached_when   // last deadline_ms seen by the wheel
}

// Build a wheel-side handle for cell.
const TimerShared::new(cell<StateCell>) TimerShared {
    s<TimerShared> = new TimerShared
    s.state              = cell
    s.pointers.prev      = null
    s.pointers.next      = null
    s.cached_when        = STATE_DEREGISTERED
    return s
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
    e.shared      = TimerShared::new(cell)
    e.deadline_ms = deadline_ms
    e.registered  = 0
    return e
}

// Mark deregistered so the wheel does not fire after Drop.
TimerEntry::cancel(){
    s<StateCell> = this.shared.state
    s.deregister()
}

// True once the deadline has fired.
TimerEntry::is_elapsed() bool {
    s<StateCell> = this.shared.state
    return s.is_pending_fire()
}

// Sleep-future hand-off: returns RESULT_FIRED when the entry has elapsed,
// RESULT_OK + 0 to keep waiting (waker armed), RESULT_CANCELLED when the
// entry has been deregistered.
TimerEntry::poll_elapsed(ctx<u64>) i32 {
    s<StateCell> = this.shared.state
    code<i32>, fired<i32> = s.poll(ctx)
    if fired != 0 return RESULT_FIRED
    return code
}

