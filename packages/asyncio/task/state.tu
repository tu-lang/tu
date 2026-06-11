// Task lifecycle bits + ref count packed into one atomic i32.
// RUNNING and COMPLETE are mutually exclusive; CANCELLED is monotonic.
// Initial state has refcount=3 (task + JoinHandle + queue), JOIN_INTEREST + NOTIFIED.
// All transitions go through std.atomic.cas in a load/CAS retry loop.

use std.atomic
use os

// Lifecycle bits.
RUNNING<i32>        = 0x01
COMPLETE<i32>       = 0x02
LIFECYCLE_MASK<i32> = 0x03

// Notification + join + cancel bits.
NOTIFIED<i32>      = 0x04
JOIN_INTEREST<i32> = 0x08
JOIN_WAKER<i32>    = 0x10
CANCELLED<i32>     = 0x20

// State portion = bits 0..5; refcount portion = bits 6..31.
STATE_MASK<i32>      = 0x3F
REF_COUNT_SHIFT<i32> = 6
REF_ONE<i32>         = 0x40
REF_COUNT_MASK<i32>  = ~STATE_MASK

INITIAL_STATE<i32> = (REF_ONE * 3) | JOIN_INTEREST | NOTIFIED

// transition_to_running result codes.
TR_Success<i32>   = 0
TR_Cancelled<i32> = 1
TR_Failed<i32>    = 2
TR_Dealloc<i32>   = 3

// transition_to_idle result codes.
TI_Ok<i32>         = 0
TI_OkNotified<i32> = 1
TI_OkDealloc<i32>  = 2
TI_Cancelled<i32>  = 3

// transition_to_notified result codes.
TN_DoNothing<i32> = 0
TN_Submit<i32>    = 1
TN_Dealloc<i32>   = 2

// Atomic packed lifecycle + refcount slot.
mem State {
    i32 val   // packed: [refcount:26 | bits:6]
}

// Construct State pre-populated with INITIAL_STATE.
const State::new() State {
    return new State { val: INITIAL_STATE }
}

// Atomic load of the packed value.
State::load() i32 {
    return atomic.load(&this.val)
}

// Bit accessors over a snapshot value (pure helpers).
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

// Acquire the RUNNING bit. Returns Cancelled / Failed / Dealloc / Success;
// on Success the NOTIFIED bit is cleared in the same CAS.
State::transition_to_running() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 return TR_Cancelled
        if (cur & RUNNING) != 0   return TR_Failed
        if (cur & COMPLETE) != 0  return TR_Failed
        newv<i32> = (cur | RUNNING) & (~NOTIFIED)
        if atomic.cas(&this.val, cur, newv) != 0 return TR_Success
    }
    return TR_Failed
}

// Pending poll exit. Returns OkNotified when self-wake fired mid-poll,
// Cancelled when CANCELLED appeared, Ok otherwise.
State::transition_to_idle() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 {
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

// Ready poll exit. Single CAS clears RUNNING + sets COMPLETE.
State::transition_to_complete() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        newv<i32> = (cur & (~RUNNING)) | COMPLETE
        if atomic.cas(&this.val, cur, newv) != 0 return 0
    }
    return 0
}

// Bump the refcount. Overflow into the lifecycle bits aborts the process.
State::ref_inc(){
    loop {
        cur<i32> = atomic.load(&this.val)
        newv<i32> = cur + REF_ONE
        if (newv & REF_COUNT_MASK) == 0 {
            os.die("task.state ref_inc overflow")
            return
        }
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}

// Drop one reference. Returns 1 when count reached zero (caller must dealloc),
// 0 otherwise. Underflow aborts.
State::ref_dec() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & REF_COUNT_MASK) == 0 {
            os.die("task.state ref_dec underflow")
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

// By-val notify: consumes one strong ref on the DoNothing/Dealloc path.
// Returns Submit when NOTIFIED was just set (caller must enqueue).
State::transition_to_notified_by_val() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        already<i32> = cur & (RUNNING | COMPLETE | NOTIFIED)
        if already != 0 {
            if (cur & REF_COUNT_MASK) == 0 {
                os.die("task.state ref_dec underflow")
                return TN_DoNothing
            }
            newv<i32> = cur - REF_ONE
            if atomic.cas(&this.val, cur, newv) != 0 {
                if (newv & REF_COUNT_MASK) == 0 return TN_Dealloc
                return TN_DoNothing
            }
            continue
        }
        newv<i32> = cur | NOTIFIED
        if atomic.cas(&this.val, cur, newv) != 0 return TN_Submit
    }
    return TN_DoNothing
}

// By-ref notify: caller's existing strong ref covers the queue entry.
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

// Set JOIN_WAKER. Returns 0 on first set, 1 if already set (treat as AlreadyConsumed).
State::set_join_waker() i32 {
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & JOIN_WAKER) != 0 return 1
        newv<i32> = cur | JOIN_WAKER
        if atomic.cas(&this.val, cur, newv) != 0 return 0
    }
    return 0
}

// Clear JOIN_WAKER so the slot can be rewritten.
State::unset_join_waker(){
    loop {
        cur<i32> = atomic.load(&this.val)
        newv<i32> = cur & (~JOIN_WAKER)
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}

// Set the CANCELLED bit. Idempotent — once set, never cleared.
State::set_cancelled(){
    loop {
        cur<i32> = atomic.load(&this.val)
        if (cur & CANCELLED) != 0 return
        newv<i32> = cur | CANCELLED
        if atomic.cas(&this.val, cur, newv) != 0 return
    }
}
