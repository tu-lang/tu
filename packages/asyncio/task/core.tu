// Stage machine + output cell. stage progresses strictly:
//   STAGE_IDLE -> STAGE_RUNNING -> STAGE_FINISHED -> STAGE_CONSUMED
// All moves go through std.atomic.cas.
// Names prefixed STAGE_ to avoid colliding with State bitflag RUNNING in state.tu
// (same package asyncio.task; Tu has no per-file linkage).

use runtime
use std.atomic

STAGE_IDLE<i32>      = 0
STAGE_RUNNING<i32>   = 1
STAGE_FINISHED<i32>  = 2
STAGE_CONSUMED<i32>  = 3

// Cell holds the future, the future's eventual output, the join-waker ctx
// slot, and the atomic stage word.
mem Cell {
    Header* header
    runtime.Future* fut_store
    i64 output_slot         // raw bits; caller re-casts via obj.(Type)
    u64 waker_slot_packed   // ctx written by JoinHandle::poll
    i32 stage               // atomic; one of STAGE_* values
}

// Build a fresh IDLE cell.
const Cell::new(header, fut) Cell {
    c<Cell> = new Cell
    c.header            = header
    c.fut_store         = fut
    c.output_slot       = 0
    c.waker_slot_packed = 0
    c.stage             = STAGE_IDLE
    return c
}

// Atomic load of the current stage.
Cell::load_stage() i32 {
    return atomic.load(&this.stage)
}

// Debug/harness helper: set stage without CAS (poll path must be RUNNING
// before store_output). Avoids outer `.stage` type-assert trap.
Cell::force_stage(s<i32>){
    this.stage = s
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

// STAGE_IDLE -> STAGE_RUNNING via CAS. Returns 1 on success, 0 otherwise.
Cell::transition_to_running() i32 {
    if atomic.cas(&this.stage, STAGE_IDLE, STAGE_RUNNING) != 0 return 1
    return 0
}

// Debug helper: write output without stage CAS.
Cell::write_output_raw(value<i64>){
    this.output_slot = value
}

// Read output_slot without consuming stage.
Cell::peek_output() i64 {
    return this.output_slot
}

// STAGE_RUNNING -> STAGE_FINISHED + write the value into the slot.
// Returns RuntimePollError when stage was not STAGE_RUNNING; slot is left
// untouched on the error path.
Cell::store_output(value<i64>) i32 {
    if atomic.cas(&this.stage, STAGE_RUNNING, STAGE_FINISHED) != 0 {
        this.output_slot = value
        return 0
    }
    return JoinErrorRuntimePollError
}

// STAGE_FINISHED -> STAGE_CONSUMED, returns (0, value) once. Subsequent
// calls return (AlreadyConsumed, 0) without tripping runtime.futuredone().
Cell::take_output() (i32, i64) {
    if atomic.cas(&this.stage, STAGE_FINISHED, STAGE_CONSUMED) != 0 {
        return 0, this.output_slot
    }
    return JoinErrorAlreadyConsumed, 0
}

