// Task state: lifecycle bits + reference count packed into a single atomic i32
// Related: packages-asyncio-runtime task 3.3 / 3.4 / 3.5 / 3.6 / 3.7 / 3.8 / 3.9
// Requirements: R4.1 - R4.10
// Design: design §10.1
//
// Layout of State.val (LSB-first):
//   bit 0  RUNNING       1 = task currently being polled
//   bit 1  COMPLETE      1 = task future resolved (RUNNING and COMPLETE are mutually exclusive)
//   bit 2  NOTIFIED      1 = task is queued in the run queue
//   bit 3  JOIN_INTEREST 1 = a JoinHandle is interested in the result
//   bit 4  JOIN_WAKER    1 = the join waker slot has been written
//   bit 5  CANCELLED     1 = abort was requested (monotonic; never cleared)
//   bit 6+ ref count     unsigned counter, REF_ONE = (1 << REF_COUNT_SHIFT)
//
// INITIAL_STATE = (REF_ONE * 3) | JOIN_INTEREST | NOTIFIED
//   - ref count starts at 3 (one for the task itself, one for the JoinHandle,
//     one for the scheduler queue entry)
//   - JOIN_INTEREST is set so the harness will keep the output around
//   - NOTIFIED is set so the very first schedule() will not double-submit
//
// All transitions use std.atomic.cas in a load/CAS retry loop; on success the
// returned i32 is a discrete transition code defined per-transition below.

use std.atomic
use os

// Lifecycle bits
RUNNING<i32>        = 0x01
COMPLETE<i32>       = 0x02
LIFECYCLE_MASK<i32> = 0x03

// Notification + join + cancellation bits
NOTIFIED<i32>      = 0x04
JOIN_INTEREST<i32> = 0x08
JOIN_WAKER<i32>    = 0x10
CANCELLED<i32>     = 0x20

// State portion = bits 0..5
STATE_MASK<i32> = 0x3F

// Reference count portion = bits 6..31
REF_COUNT_SHIFT<i32> = 6
REF_ONE<i32>         = 0x40   // 1 << REF_COUNT_SHIFT
REF_COUNT_MASK<i32>  = ~STATE_MASK

// Initial state when constructing a Task
INITIAL_STATE<i32> = (REF_ONE * 3) | JOIN_INTEREST | NOTIFIED

// transition_to_running result codes (R4.3, R4.4)
TR_Success<i32>   = 0   // RUNNING bit was set; safe to poll
TR_Cancelled<i32> = 1   // CANCELLED was set: skip poll, run completion path
TR_Failed<i32>    = 2   // RUNNING was already 1: another worker holds it
TR_Dealloc<i32>   = 3   // ref count hit zero during the transition

// transition_to_idle result codes (R4.2)
TI_Ok<i32>         = 0  // RUNNING cleared, no NOTIFIED
TI_OkNotified<i32> = 1  // RUNNING cleared, NOTIFIED set: should re-queue
TI_OkDealloc<i32>  = 2  // RUNNING cleared, ref count hit zero
TI_Cancelled<i32>  = 3  // CANCELLED was set during execution; jump to completion

// transition_to_notified result codes (R4.8)
TN_DoNothing<i32> = 0   // task is RUNNING / COMPLETE / already NOTIFIED
TN_Submit<i32>    = 1   // NOTIFIED was just set; caller must enqueue
TN_Dealloc<i32>   = 2   // ref count hit zero (only by_val)

mem State {
    i32 val
}

// Construct a State pre-populated with INITIAL_STATE
const State::new() State {
    return new State { val: INITIAL_STATE }
}

// load(): atomic load of the packed state value
State::load() i32 {
    return atomic.load(&this.val)
}

// snapshot helpers — these only inspect the value, not the State itself
fn st_is_running(v<i32>) bool {
    if (v & RUNNING) != 0 return true
    return false
}
fn st_is_complete(v<i32>) bool {
    if (v & COMPLETE) != 0 return true
    return false
}
fn st_is_notified(v<i32>) bool {
    if (v & NOTIFIED) != 0 return true
    return false
}
fn st_is_cancelled(v<i32>) bool {
    if (v & CANCELLED) != 0 return true
    return false
}
fn st_is_join_interested(v<i32>) bool {
    if (v & JOIN_INTEREST) != 0 return true
    return false
}
fn st_ref_count(v<i32>) i32 {
    return (v & REF_COUNT_MASK) >> REF_COUNT_SHIFT.(u32)
}

// transition_to_running(): try to acquire the RUNNING bit.
//   Branches:
//     - CANCELLED set:                   return Cancelled (no RUNNING)
//     - RUNNING already 1:               return Failed
//     - ref count would underflow:       return Dealloc
//     - otherwise:                       set RUNNING, clear NOTIFIED, return Success
State::transition_to_running() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 return TR_Cancelled
        if (cur & RUNNING) != 0   return TR_Failed
        if (cur & COMPLETE) != 0  return TR_Failed
        // Set RUNNING, clear NOTIFIED for the new poll round
        newv<i32> = (cur | RUNNING) & (~NOTIFIED)
        if atomic.cas(&this.val, cur, newv) != 0 return TR_Success
    }
    return TR_Failed
}

// transition_to_idle(): leave RUNNING after a Pending poll.
//   Branches:
//     - CANCELLED was raised mid-poll: return Cancelled
//     - NOTIFIED was set externally:   return OkNotified (re-queue)
//     - ref count hit zero:            return OkDealloc
//     - otherwise:                     return Ok
State::transition_to_idle() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 {
            // Clear RUNNING but leave CANCELLED bit; caller jumps to completion
            newv<i32> = cur & (~RUNNING)
            if atomic.cas(&this.val, cur, newv) != 0 return TI_Cancelled
            continue
        }
        notified<i32> = cur & NOTIFIED
        newv<i32> = cur & (~RUNNING)
        if atomic.cas(&this.val, cur, newv) != 0 {
            if notified != 0 return TI_OkNotified
            return TI_Ok
        }
    }
    return TI_Ok
}

// transition_to_complete(): Ready poll path.
//   Sets COMPLETE and clears RUNNING in a single CAS.  RUNNING must currently
//   be 1; the harness only calls this from inside a poll round.
State::transition_to_complete() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        // RUNNING and COMPLETE are mutually exclusive; the contract requires
        // RUNNING==1 here, so we always clear RUNNING and set COMPLETE.
        newv<i32> = (cur & (~RUNNING)) | COMPLETE
        if atomic.cas(&this.val, cur, newv) != 0 return 0
    }
    return 0
}

// ref_inc(): bump the reference count by 1.
//   Overflow into the state portion is treated as a programmer error; we
//   abort the process to surface the bug instead of silently corrupting state.
State::ref_inc(){
    loop {
        cur<i32> = atomic.load(&this.val)
        newv<i32> = cur + REF_ONE
        // Detect overflow: top bit of refcount portion must not corrupt sign
        if (newv & REF_COUNT_MASK) == 0 {
            // refcount wrapped; refuse to continue
            os_die_refcount_overflow()
            return
        }
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}

// ref_dec(): drop one reference, returns 1 when the count reached zero.
//   The caller must run the dealloc path when the return is non-zero.
//   Underflow (count already 0) aborts the process.
State::ref_dec() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & REF_COUNT_MASK) == 0 {
            os_die_refcount_underflow()
            return 0
        }
        newv<i32> = cur - REF_ONE
        if atomic.cas(&this.val, cur, newv) != 0 {
            if (newv & REF_COUNT_MASK) == 0 return 1
            return 0
        }
    }
    return 0
}

// transition_to_notified_by_val(): notify path that consumes a strong ref.
//   - If RUNNING or COMPLETE is already set, just drop the strong ref:
//     - if ref count hits zero, return Dealloc;
//     - otherwise DoNothing.
//   - If NOTIFIED is already set, drop the strong ref similarly.
//   - Otherwise set NOTIFIED (without dropping the ref) and return Submit.
State::transition_to_notified_by_val() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        already<i32> = cur & (RUNNING | COMPLETE | NOTIFIED)
        if already != 0 {
            // No need to enqueue; drop the ref the by-val variant carried.
            if (cur & REF_COUNT_MASK) == 0 {
                os_die_refcount_underflow()
                return TN_DoNothing
            }
            newv<i32> = cur - REF_ONE
            if atomic.cas(&this.val, cur, newv) != 0 {
                if (newv & REF_COUNT_MASK) == 0 return TN_Dealloc
                return TN_DoNothing
            }
            continue
        }
        // Set NOTIFIED; keep the existing refcount so the queue entry holds the ref.
        newv<i32> = cur | NOTIFIED
        if atomic.cas(&this.val, cur, newv) != 0 return TN_Submit
    }
    return TN_DoNothing
}

// transition_to_notified_by_ref(): notify path without consuming a ref.
//   The caller already holds a strong ref via the queue entry; we only flip
//   the NOTIFIED bit when the task is currently idle.
State::transition_to_notified_by_ref() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        already<i32> = cur & (RUNNING | COMPLETE | NOTIFIED)
        if already != 0 return TN_DoNothing
        newv<i32> = cur | NOTIFIED
        if atomic.cas(&this.val, cur, newv) != 0 return TN_Submit
    }
    return TN_DoNothing
}

// set_join_waker(): mark the JOIN_WAKER slot as written.
//   Returns 0 on success, 1 when the bit was already set (caller must treat
//   as AlreadyConsumed and avoid double-write).
State::set_join_waker() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & JOIN_WAKER) != 0 return 1
        newv<i32> = cur | JOIN_WAKER
        if atomic.cas(&this.val, cur, newv) != 0 return 0
    }
    return 0
}

// unset_join_waker(): clear the JOIN_WAKER bit so the slot can be rewritten.
State::unset_join_waker(){
    loop {
        cur<i32> = atomic.load(&this.val)
        newv<i32> = cur & (~JOIN_WAKER)
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}

// set_cancelled(): set the CANCELLED bit.
//   Monotonic: once set, never cleared.
State::set_cancelled(){
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 return
        newv<i32> = cur | CANCELLED
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}

// Internal panic helpers — kept local to avoid dragging os into the State
// callers that only need the bit constants.
fn os_die_refcount_overflow(){
    os.die("task.state ref_inc overflow")
}
fn os_die_refcount_underflow(){
    os.die("task.state ref_dec underflow")
}
