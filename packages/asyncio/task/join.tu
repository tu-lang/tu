// JoinHandle: leaf future that yields the spawned task's output
// Related: packages-asyncio-runtime task 3.31 / 3.32 / 3.33, R9.1 - R9.5
// Design: design §11
//
// JoinHandle is a leaf future (`mem ... : async`) implementing poll(ctx).
// State machine:
//   - first poll while task is RUNNING / IDLE: register ctx as the join
//     waker (Cell.join_ctx_packed + State::set_join_waker), return Pending.
//   - State has COMPLETE bit set and consumed == 0: try_read_output via the
//     vtable, set consumed=1, return PollReady, value.
//   - State has COMPLETE bit set and consumed == 1: return PollReady,
//     AlreadyConsumed.  Never trips runtime.futuredone() (R9.3).

use runtime
use asyncio.error as aerr

mem JoinHandle: async {
    raw       // RawTask*
    i32 consumed
}

JoinHandle::init(raw){
    this.raw = raw
    this.consumed = 0
}

// register_join_waker(raw, ctx): write ctx into the cell's slot and flag
// JOIN_WAKER on the State.
//   Returns 0 on success or aerr.AlreadyConsumed when JOIN_WAKER was already
//   set (handler should treat as Pending without rewriting).
fn register_join_waker(raw, ctx<u64>) i32 {
    h<Header> = raw.hdr
    cell<Cell> = raw.cell
    // Store ctx first; set_join_waker publishes the slot to readers.
    cell.join_ctx_packed = ctx
    st<State> = h.state
    return st.set_join_waker()
}

JoinHandle::poll(ctx){
    if this.raw == null {
        return runtime.PollReady, aerr.AlreadyConsumed
    }
    if this.consumed == 1 {
        // Repeat-poll path: leaf future has already yielded its value once.
        return runtime.PollReady, aerr.AlreadyConsumed
    }
    raw = this.raw
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.load()

    if (snap & COMPLETE) == 0 {
        // Task not finished yet; arm the join waker and yield.
        register_join_waker(raw, ctx.(u64))
        return runtime.PollPending
    }

    // COMPLETE is set: read the output through the RawVTable's
    // try_read_output entry.  We deliberately fetch it as a function pointer
    // because the harness installs vtable.try_read_output during its own
    // package init.
    vt<RawVTable> = raw.vtable
    fc<vtable_try_read_output> = vt.try_read_output.(u64)
    err<i32>, val<i64> = fc(raw)
    this.consumed = 1
    if err == 0 {
        return runtime.PollReady, val
    }
    return runtime.PollReady, err
}

// vtable_try_read_output: signature alias for casting RawVTable.try_read_output
fn vtable_try_read_output(raw) i32, i64
