// Task lifecycle bits + ref count packed into one atomic i32.
// RUNNING and COMPLETE are mutually exclusive; CANCELLED is monotonic.
// Initial state has refcount=3 (task + JoinHandle + queue), JOIN_INTEREST + NOTIFIED.
// All transitions go through std.atomic.cas in a load/CAS retry loop.
// Tu name is TaskState because
// bare `State` corrupted the stack on new/return under current codegen.

use std.atomic
use os

// CAS success sentinel: std.atomic cas/cas64 return 1 on success;
// comparing against an untyped literal 0 crashes codegen (binary-op trap).
CAS_OK<i32> = 1
CAS64_OK<i64> = 1

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
REF_COUNT_MASK<i32>  = 0xFFFFFFC0

INITIAL_STATE<i32> = 0xCC

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
mem TaskState {
    u64 slot_word // packed: [refcount:26 | bits:6]
}

// Construct TaskState pre-populated with INITIAL_STATE.
const TaskState::new() TaskState {
    return new TaskState { slot_word: INITIAL_STATE.(u64) }
}

// Atomic load of the packed value.
TaskState::load() i32 {
    w<u64> = atomic.load64(&this.slot_word)
    return w.(i32)
}

// Bit accessors over a snapshot value (pure helpers).
fn st_is_running(v<i32>) i32 {
    if (v & RUNNING) != 0 return 1
    return 0
}
fn st_is_complete(v<i32>) i32 {
    if (v & COMPLETE) != 0 return 1
    return 0
}
fn st_is_notified(v<i32>) i32 {
    if (v & NOTIFIED) != 0 return 1
    return 0
}
fn st_is_cancelled(v<i32>) i32 {
    if (v & CANCELLED) != 0 return 1
    return 0
}
fn st_is_join_interested(v<i32>) i32 {
    if (v & JOIN_INTEREST) != 0 return 1
    return 0
}
fn st_ref_count(v<i32>) i32 {
    return (v & REF_COUNT_MASK) >> REF_COUNT_SHIFT.(u32)
}

// Acquire the RUNNING bit.
// Not idle: the notification ref is consumed -> Failed / Dealloc.
// Idle: set RUNNING + clear NOTIFIED in one CAS; report Cancelled when the
// CANCELLED bit was already set (RUNNING is still taken, caller completes).
TaskState::transition_to_running() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & LIFECYCLE_MASK) != 0 {
            if (cur & REF_COUNT_MASK) == 0 {
                os.die("task.state transition_to_running underflow")
                return TR_Failed
            }
            new_state<i32> = cur - REF_ONE
            if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK {
                if (new_state & REF_COUNT_MASK) == 0 { return TR_Dealloc }
                return TR_Failed
            }
            continue
        }
        new_state<i32> = (cur | RUNNING) & 0xFFFFFFFB
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK {
            if (new_state & CANCELLED) != 0 { return TR_Cancelled }
            return TR_Success
        }
    }
    return TR_Failed
}

// Pending poll exit.
// Cancelled: state untouched, caller must cancel + complete.
// Not notified: polling consumed the Notified ref -> ref_dec (Ok/OkDealloc).
// Notified during poll: keep our ref + ref_inc for the new Notified the
// caller will submit -> OkNotified.
TaskState::transition_to_idle() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & CANCELLED) != 0 { return TI_Cancelled }
        if (cur & NOTIFIED) == 0 {
            if (cur & REF_COUNT_MASK) == 0 {
                os.die("task.state transition_to_idle underflow")
                return TI_Ok
            }
            new_state<i32> = (cur & 0xFFFFFFFE) - REF_ONE
            if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK {
                if (new_state & REF_COUNT_MASK) == 0 { return TI_OkDealloc }
                return TI_Ok
            }
            continue
        }
        new_state<i32> = (cur & 0xFFFFFFFE) + REF_ONE
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return TI_OkNotified }
    }
    return TI_Ok
}

// Ready poll exit. Single CAS clears RUNNING + sets COMPLETE.
// Returns the post-transition snapshot for join-waker checks.
TaskState::transition_to_complete() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        new_state<i32> = (cur & 0xFFFFFFFE) | COMPLETE
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return new_state }
    }
    return 0
}

// Bump the refcount. Overflow into the lifecycle bits aborts the process.
TaskState::ref_inc(){
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        new_state<i32> = cur + REF_ONE
        if (new_state & REF_COUNT_MASK) == 0 {
            os.die("task.state ref_inc overflow")
            return
        }
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return }
    }
}

// Drop one reference. Returns 1 when count reached zero (caller must dealloc),
// 0 otherwise. Underflow aborts.
TaskState::ref_dec() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & REF_COUNT_MASK) == 0 {
            os.die("task.state ref_dec underflow")
            return 0
        }
        new_state<i32> = cur - REF_ONE
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK {
            if (new_state & REF_COUNT_MASK) == 0 return 1
            return 0
        }
    }
    return 0
}

// By-val notify.
// RUNNING: set NOTIFIED (poller re-enqueues on idle) and consume our ref.
// COMPLETE/NOTIFIED: just consume the ref (may reach zero -> Dealloc).
// Idle: set NOTIFIED + ref_inc for the new Notified -> Submit.
TaskState::transition_to_notified_by_val() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & RUNNING) != 0 {
            if (cur & REF_COUNT_MASK) == 0 {
                os.die("task.state notified_by_val underflow")
                return TN_DoNothing
            }
            new_state<i32> = (cur | NOTIFIED) - REF_ONE
            if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return TN_DoNothing }
            continue
        }
        if (cur & (COMPLETE | NOTIFIED)) != 0 {
            if (cur & REF_COUNT_MASK) == 0 {
                os.die("task.state notified_by_val underflow")
                return TN_DoNothing
            }
            new_state<i32> = cur - REF_ONE
            if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK {
                if (new_state & REF_COUNT_MASK) == 0 { return TN_Dealloc }
                return TN_DoNothing
            }
            continue
        }
        new_state<i32> = (cur | NOTIFIED) + REF_ONE
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return TN_Submit }
    }
    return TN_DoNothing
}

// By-ref notify.
// COMPLETE/NOTIFIED: nothing to do. RUNNING: set NOTIFIED only (the poller
// re-enqueues on idle). Idle: set NOTIFIED + ref_inc -> Submit.
TaskState::transition_to_notified_by_ref() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & (COMPLETE | NOTIFIED)) != 0 { return TN_DoNothing }
        if (cur & RUNNING) != 0 {
            new_state<i32> = cur | NOTIFIED
            if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return TN_DoNothing }
            continue
        }
        new_state<i32> = (cur | NOTIFIED) + REF_ONE
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return TN_Submit }
    }
    return TN_DoNothing
}

// Arm JOIN_WAKER. Returns 0 on success, -1 when JOIN_INTEREST is gone.
TaskState::set_join_waker() i32 {
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        if (cur & JOIN_INTEREST) == 0 return -1
        new_state<i32> = cur | JOIN_WAKER
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK return 0
    }
    return -1
}

// Clear JOIN_WAKER.
TaskState::unset_join_waker(){
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        new_state<i32> = cur & 0xFFFFFFEF
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return }
    }
}

// Set CANCELLED (monotonic).
TaskState::set_cancelled(){
    loop {
        w<u64> = atomic.load64(&this.slot_word)
        cur<i32> = w.(i32)
        new_state<i32> = cur | CANCELLED
        if atomic.cas64(&this.slot_word, cur.(i64), new_state.(i64)) == CAS64_OK { return }
    }
}
