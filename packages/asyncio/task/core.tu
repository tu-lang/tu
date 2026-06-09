// Task core: stage machine and output cell
// Related: packages-asyncio-runtime task 3.14 / 3.15, R6.1 - R6.5
// Design: design §10.3
//
// Stage transitions are strictly monotonic:
//     IDLE --(transition_to_running)--> RUNNING
//     RUNNING --(store_output)--------> FINISHED
//     FINISHED --(take_output)--------> CONSUMED
//
// All stage moves go through std.atomic.cas so multi-threaded harnesses see
// the same monotone progression.

use std.atomic
use asyncio.error as aerr
use io

// Stage values
IDLE<i32>      = 0
RUNNING<i32>   = 1
FINISHED<i32>  = 2
CONSUMED<i32>  = 3

mem Cell {
    hdr              // Header*
    fut              // runtime.Future*
    i64 output_slot
    u64 join_ctx_packed
    i32 stage
}

// new(hdr, fut): build a fresh Cell in IDLE stage.
//   output_slot and join_ctx_packed are zeroed; the harness writes them
//   through store_output / register_join_waker on demand.
const Cell::new(hdr, fut) Cell {
    c<Cell> = new Cell
    c.hdr               = hdr
    c.fut               = fut
    c.output_slot       = 0
    c.join_ctx_packed   = 0
    c.stage             = IDLE
    return c
}

// load_stage(): atomic load of the stage value
Cell::load_stage() i32 {
    return atomic.load(&this.stage)
}

// transition_to_running(): IDLE -> RUNNING via CAS.
//   Returns 1 on success, 0 if the cell was not in IDLE (caller must reject).
Cell::transition_to_running() i32 {
    if atomic.cas(&this.stage, IDLE, RUNNING) != 0 return 1
    return 0
}

// store_output(value): RUNNING -> FINISHED, write value into output_slot.
//   The slot is i64; Cell does not interpret the bits.  Callers carry the
//   real type out-of-band and re-cast on take_output (`obj.(Type)`).
//   Returns io.Ok on success or asyncio.error.RuntimePollError when stage is
//   not RUNNING (R6.2).  The slot is left untouched on the error path.
Cell::store_output(value<i64>) i32 {
    if atomic.cas(&this.stage, RUNNING, FINISHED) != 0 {
        this.output_slot = value
        return 0
    }
    return aerr.RuntimePollError
}

// take_output(): FINISHED -> CONSUMED, returns (io.Ok, value) on first take
// or (asyncio.error.AlreadyConsumed, 0) on any subsequent call (R6.4).
//   The CONSUMED state is sticky so this never trips runtime.futuredone(),
//   even after the underlying future has finalised.
Cell::take_output() (i32, i64) {
    if atomic.cas(&this.stage, FINISHED, CONSUMED) != 0 {
        return 0, this.output_slot
    }
    // Either FINISHED never happened or another caller already consumed.
    return aerr.AlreadyConsumed, 0
}
