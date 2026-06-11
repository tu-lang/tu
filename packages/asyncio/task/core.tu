// Stage machine + output cell. stage progresses strictly:
//   IDLE -> RUNNING -> FINISHED -> CONSUMED
// All moves go through std.atomic.cas.

use std.atomic
use asyncio.error as aerr

IDLE<i32>      = 0
RUNNING<i32>   = 1
FINISHED<i32>  = 2
CONSUMED<i32>  = 3

// Cell holds the future, the future's eventual output, the join-waker ctx
// slot, and the atomic stage word.
mem Cell {
    hdr                     // Header*
    fut                     // runtime.Future*
    i64 output_slot         // i64 raw bits; caller re-casts via obj.(Type)
    u64 join_ctx_packed     // ctx written by JoinHandle::poll
    i32 stage               // atomic; one of IDLE/RUNNING/FINISHED/CONSUMED
}

// Build a fresh IDLE cell.
const Cell::new(hdr, fut) Cell {
    c<Cell> = new Cell
    c.hdr               = hdr
    c.fut               = fut
    c.output_slot       = 0
    c.join_ctx_packed   = 0
    c.stage             = IDLE
    return c
}

// Atomic load of the current stage.
Cell::load_stage() i32 {
    return atomic.load(&this.stage)
}

// IDLE -> RUNNING via CAS. Returns 1 on success, 0 otherwise.
Cell::transition_to_running() i32 {
    if atomic.cas(&this.stage, IDLE, RUNNING) != 0 return 1
    return 0
}

// RUNNING -> FINISHED + write the value into the slot.
// Returns RuntimePollError when stage was not RUNNING; slot is left untouched
// on the error path.
Cell::store_output(value<i64>) i32 {
    if atomic.cas(&this.stage, RUNNING, FINISHED) != 0 {
        this.output_slot = value
        return 0
    }
    return aerr.RuntimePollError
}

// FINISHED -> CONSUMED, returns (0, value) once. Subsequent calls return
// (AlreadyConsumed, 0) without tripping runtime.futuredone().
Cell::take_output() (i32, i64) {
    if atomic.cas(&this.stage, FINISHED, CONSUMED) != 0 {
        return 0, this.output_slot
    }
    return aerr.AlreadyConsumed, 0
}
