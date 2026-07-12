// Stage machine + output cell. stage progresses strictly:
//   IDLE -> RUNNING -> FINISHED -> CONSUMED
// All moves go through std.atomic.cas.

use runtime
use std.atomic

IDLE<i32>      = 0
RUNNING<i32>   = 1
FINISHED<i32>  = 2
CONSUMED<i32>  = 3

// Cell holds the future, the future's eventual output, the join-waker ctx
// slot, and the atomic stage word.
mem Cell {
    Header* header
    runtime.Future* fut
    i64 output_slot         // raw bits; caller re-casts via obj.(Type)
    u64 waker_slot_packed   // ctx written by JoinHandle::poll
    i32 stage               // atomic; one of IDLE/RUNNING/FINISHED/CONSUMED
}

// Build a fresh IDLE cell.
const Cell::new(header, fut) Cell {
    c<Cell> = new Cell
    c.header            = header
    c.fut               = fut
    c.output_slot       = 0
    c.waker_slot_packed = 0
    c.stage             = IDLE
    return c
}

// Atomic load of the current stage.
Cell::load_stage() i32 {
    return atomic.load(&this.stage)
}

// Store join-waker ctx for wake_join_waker.
Cell::write_packed_waker(v<u64>){
    this.waker_slot_packed = v
}

// Load join-waker ctx.
Cell::read_packed_waker() u64 {
    return this.waker_slot_packed
}

// Overwrite output slot with an error code (JoinHandle error path).
Cell::store_output_err(err<i32>){
    this.output_slot = err.(i64)
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
    return JoinErrorRuntimePollError
}

// FINISHED -> CONSUMED, returns (0, value) once. Subsequent calls return
// (AlreadyConsumed, 0) without tripping runtime.futuredone().
Cell::take_output() (i32, i64) {
    if atomic.cas(&this.stage, FINISHED, CONSUMED) != 0 {
        return 0, this.output_slot
    }
    return JoinErrorAlreadyConsumed, 0
}

