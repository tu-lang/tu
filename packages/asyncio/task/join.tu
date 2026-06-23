// Leaf future yielding the spawned task's output. consumed is monotonic so
// repeat polls return AlreadyConsumed instead of tripping futuredone().

use runtime
use asyncio.error as aerr

// Async leaf future; State.JOIN_WAKER + Cell.join_ctx_packed track the waker.
mem JoinHandle: async {
    RawTask* raw    // null when the task has been released
    i32 consumed    // monotonic 0->1 once the value is taken
}

// Initialise a JoinHandle around raw.
JoinHandle::init(raw<RawTask>){
    this.raw = raw
    this.consumed = 0
}

// Stash ctx in the cell slot before flagging JOIN_WAKER on State; returns
// 0 on first arm, AlreadyConsumed when JOIN_WAKER was already set.
fn register_join_waker(raw<RawTask>, ctx<u64>) i32 {
    cell<Cell> = raw.cell
    cell.join_ctx_packed = ctx
    h<Header> = raw.hdr
    st<State> = h.state
    return st.set_join_waker()
}

// Poll the JoinHandle.
//   - released cell      -> PollReady, AlreadyConsumed
//   - already consumed   -> PollReady, AlreadyConsumed
//   - task not done yet  -> arm join waker, PollPending
//   - task done          -> read output via vtable, mark consumed, PollReady
JoinHandle::poll(ctx){
    if this.raw == null {
        return runtime.PollReady, aerr.AlreadyConsumed
    }
    if this.consumed == 1 {
        return runtime.PollReady, aerr.AlreadyConsumed
    }
    raw<RawTask> = this.raw
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.load()

    if (snap & COMPLETE) == 0 {
        register_join_waker(raw, ctx.(u64))
        return runtime.PollPending
    }

    vt<RawVTable> = raw.vtable
    fc<vtable_try_read_output> = vt.try_read_output.(u64)
    err<i32>, val<i64> = fc(raw)
    this.consumed = 1
    if err == 0 {
        return runtime.PollReady, val
    }
    return runtime.PollReady, err
}

// Signature alias for casting RawVTable.try_read_output back to a callable.
fn vtable_try_read_output(raw) (i32, i64)

