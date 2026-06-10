// Task harness: drives one polling round end-to-end
// Related: packages-asyncio-runtime task 3.19 / 3.20 / 3.21, R7.1 - R7.8
// Design: design §10.5
//
// The scheduler does NOT call into the future directly; it always goes
// through `harness_poll(raw, ctx)`.  The harness:
//   1. transitions State to RUNNING (or routes to cancel / dealloc paths);
//   2. invokes the future's poll continuation via VObjFunc.entry;
//   3. interprets the (PollPending | PollReady | PollError) return value;
//   4. on completion, writes the output, wakes the join waker, and drops the
//      task's own ref (which may trigger dealloc).
//
// The harness also exposes `harness_complete(raw, err, output)` so leaf
// futures inside cooperative cancellation can short-circuit to completion.

use runtime
use io
use asyncio.error as aerr

// vtable_poll signature: (RawTask, u64 ctx) — used to install harness_poll
// into RawVTable.poll.
fn vtable_poll(raw, ctx<u64>)

// vtable_dealloc signature: (RawTask)
fn vtable_dealloc(raw)

// vtable_try_read_output_h signature: (RawTask) -> (i32, i64)
fn vtable_try_read_output_h(raw) i32, i64

// vtable_drop_join_handle_slow signature: (RawTask)
fn vtable_drop_join_handle_slow(raw)

// vtable_shutdown signature: (RawTask)
fn vtable_shutdown(raw)

// future_poll signature: (Future*, u64 ctx) -> (i64 ready, i64 result)
//   matches runtime.VObjFunc.entry.
fn future_poll(fut, ctx<u64>) i64, i64

// harness_poll(raw, ctx): single polling round.
//   The scheduler calls this with `ctx = pack(scheduler_handle, task_id)`.
//   On any terminal branch the harness returns; the caller does not interpret
//   the lack of return value beyond "this round done".
fn harness_poll(raw, ctx<u64>){
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.transition_to_running()
    if snap == TR_Cancelled {
        harness_complete(raw, aerr.Cancelled, 0)
        return
    }
    if snap == TR_Failed {
        // Another worker already holds RUNNING; abort this round.
        return
    }
    if snap == TR_Dealloc {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
        return
    }

    // TR_Success: enter Cell::transition_to_running too so stage moves to
    // RUNNING in lock-step.  If Cell already went to RUNNING in a previous
    // attempt that failed mid-flight, we tolerate a non-monotonic state and
    // keep going — the future itself is the single source of completion.
    cell<Cell> = raw.cell
    cell.transition_to_running()

    // Drive the future via its VObjFunc.entry.
    fut = raw.fut
    f<runtime.Future> = fut.(runtime.Future)
    virf<runtime.VObjFunc> = f.virf
    fc_poll<future_poll> = virf.entry.(u64)
    ready<i64>, output<i64> = fc_poll(fut, ctx)

    if ready == runtime.PollPending {
        idle<i32> = st.transition_to_idle()
        if idle == TI_OkNotified {
            // Self-wake before yielding: re-enqueue immediately.
            sched = h.scheduler
            if sched != null {
                n<Notified> = notified_from_raw(raw)
                sched.schedule(n)
            }
            return
        }
        if idle == TI_OkDealloc {
            vt<RawVTable> = raw.vtable
            fc_dealloc<vtable_dealloc> = vt.dealloc.(u64)
            fc_dealloc(raw)
            return
        }
        if idle == TI_Cancelled {
            harness_complete(raw, aerr.Cancelled, 0)
            return
        }
        // TI_Ok: yield, do nothing further.
        return
    }
    if ready == runtime.PollReady {
        harness_complete(raw, 0, output)
        return
    }
    // PollError or unexpected code: surface as RuntimePollError.
    harness_complete(raw, aerr.RuntimePollError, 0)
}

// harness_complete(raw, err, output): finalise the task.
//   - On the success path (`err == 0`) writes `output` into Cell.output_slot;
//   - on any error path the slot holds 0 and JoinHandle returns the err code;
//   - flips State to COMPLETE so JoinHandle sees the readiness;
//   - wakes the join waker exactly once (R7.7);
//   - drops the task's own strong ref (may trigger dealloc) (R7.8).
fn harness_complete(raw, err<i32>, output<i64>){
    cell<Cell> = raw.cell
    h<Header> = raw.hdr
    st<State> = h.state

    // store_output is allowed to fail when stage already moved past RUNNING
    // (e.g. cancellation came in first).  In that case we still wake / dec.
    cell.store_output(output)
    st.transition_to_complete()

    // Stash the error code into output_slot's high bits-equivalent: callers
    // read err separately by checking JoinHandle::poll's path.  For now keep
    // the slot as the "value" portion; JoinHandle re-checks State for cancel.
    if err != 0 {
        // Use a side channel by writing err into the slot when output==0.
        // The caller of try_read_output sees (err, 0) on cancellation.
        cell.output_slot = err.(i64)
    }

    wake_join_waker(raw)

    if st.ref_dec() != 0 {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
    }
}

// wake_join_waker(raw): rouse the waker registered by JoinHandle::poll, if
// any.  Idempotent: JOIN_WAKER bit is cleared on the first wake so a second
// completion path no-ops.
fn wake_join_waker(raw){
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.load()
    if (snap & JOIN_WAKER) == 0 return

    cell<Cell> = raw.cell
    ctx<u64> = cell.join_ctx_packed
    // Clear JOIN_WAKER first so a subsequent register can rearm; the slot
    // value is consumed by the caller-defined wake hook.
    st.unset_join_waker()

    // The actual wake-by-ctx is scheduler-specific.  In the first phase we
    // simply re-enqueue the task itself: the join future's poll(ctx) saw
    // the COMPLETE bit and will return Ready next round.  Schedulers that
    // pack a different shape into ctx are free to override this default.
    sched = h.scheduler
    if sched == null return
    if ctx == 0 return
    n<Notified> = notified_from_raw(raw)
    sched.schedule(n)
}

// vtable_dealloc_default(raw): minimal dealloc placeholder.
//   Phase-1 implementation just nulls out the cross references; full GC
//   integration is task 3.18 follow-up work.
fn harness_dealloc_default(raw){
    raw.hdr     = null
    raw.fut     = null
    raw.cell    = null
    raw.vtable  = null
}

// harness_try_read_output_default(raw): the default vtable.try_read_output.
//   Wraps Cell::take_output and surfaces (err, value).  When err != 0 the
//   value is whatever last lived in the slot (often 0); JoinHandle::poll
//   bridges err codes appropriately.
fn harness_try_read_output_default(raw) i32, i64 {
    cell<Cell> = raw.cell
    err<i32>, val<i64> = cell.take_output()
    return err, val
}

// harness_drop_join_handle_slow_default(raw): the slow path for
// JoinHandle::drop.  In Phase 1 we simply drop one strong ref; if it brings
// refcount to zero we dealloc.
fn harness_drop_join_handle_slow_default(raw){
    h<Header> = raw.hdr
    st<State> = h.state
    if st.ref_dec() != 0 {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
    }
}

// harness_shutdown_default(raw): runtime-shutdown hook.
//   Set CANCELLED + ensure one schedule kick fires (the scheduler's drain
//   loop will then push the task through harness_poll which short-circuits).
fn harness_shutdown_default(raw){
    h<Header> = raw.hdr
    st<State> = h.state
    st.set_cancelled()
    code<i32> = st.transition_to_notified_by_ref()
    if code == TN_Submit {
        sched = h.scheduler
        if sched != null {
            n<Notified> = notified_from_raw(raw)
            sched.schedule(n)
        }
    }
}

// init(): wire harness functions into the default RawVTable.  Called once at
// package init time; multiple invocations are safe (last-writer-wins, the
// installed addresses do not change).
func init(){
    raw_vtable_install(
        harness_poll.(u64),
        harness_dealloc_default.(u64),
        harness_try_read_output_default.(u64),
        harness_drop_join_handle_slow_default.(u64),
        harness_shutdown_default.(u64)
    )
}
