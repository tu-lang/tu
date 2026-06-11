// Single polling round driver. Schedulers always go through harness_poll;
// it transitions State, invokes the future via VObjFunc.entry, then routes
// PollPending / PollReady / PollError to the right path. harness_complete
// is also reused by leaf futures that short-circuit via cancellation.
// Default RawVTable slots are wired in `init()` at package load time.

use runtime
use asyncio.error as aerr

// Signature aliases used to cast the u64 vtable slots back to callables.
fn vtable_poll(raw, ctx<u64>)
fn vtable_dealloc(raw)
fn vtable_try_read_output_h(raw) i32, i64
fn vtable_drop_join_handle_slow(raw)
fn vtable_shutdown(raw)
fn future_poll(fut, ctx<u64>) i64, i64

// Run one polling round on raw. ctx packs (scheduler_handle, task_id);
// harness does not interpret it but threads it through to the future.
fn harness_poll(raw, ctx<u64>){
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.transition_to_running()
    if snap == TR_Cancelled {
        harness_complete(raw, aerr.Cancelled, 0)
        return
    }
    if snap == TR_Failed {
        return
    }
    if snap == TR_Dealloc {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
        return
    }

    cell<Cell> = raw.cell
    cell.transition_to_running()

    fut = raw.fut
    f<runtime.Future> = fut.(runtime.Future)
    virf<runtime.VObjFunc> = f.virf
    fc_poll<future_poll> = virf.entry.(u64)
    ready<i64>, output<i64> = fc_poll(fut, ctx)

    if ready == runtime.PollPending {
        idle<i32> = st.transition_to_idle()
        if idle == TI_OkNotified {
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
        return
    }
    if ready == runtime.PollReady {
        harness_complete(raw, 0, output)
        return
    }
    harness_complete(raw, aerr.RuntimePollError, 0)
}

// Finalise the task: write output, flip COMPLETE, wake the join waker, drop
// the task's own ref. err != 0 overwrites output_slot with the err code as
// a side channel JoinHandle picks up.
fn harness_complete(raw, err<i32>, output<i64>){
    cell<Cell> = raw.cell
    h<Header> = raw.hdr
    st<State> = h.state

    cell.store_output(output)
    st.transition_to_complete()

    if err != 0 {
        cell.output_slot = err.(i64)
    }

    wake_join_waker(raw)

    if st.ref_dec() != 0 {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
    }
}

// Idempotent join-waker kick: JOIN_WAKER is cleared on the first wake so a
// second completion path no-ops. Re-enqueue the task as the wake hook.
fn wake_join_waker(raw){
    h<Header> = raw.hdr
    st<State> = h.state
    snap<i32> = st.load()
    if (snap & JOIN_WAKER) == 0 return

    cell<Cell> = raw.cell
    ctx<u64> = cell.join_ctx_packed
    st.unset_join_waker()

    sched = h.scheduler
    if sched == null return
    if ctx == 0 return
    n<Notified> = notified_from_raw(raw)
    sched.schedule(n)
}

// Default vtable.dealloc: null out cross references so future use surfaces
// as a clear crash. Real GC integration is follow-up work.
fn harness_dealloc_default(raw){
    raw.hdr     = null
    raw.fut     = null
    raw.cell    = null
    raw.vtable  = null
}

// Default vtable.try_read_output: bridges Cell::take_output.
fn harness_try_read_output_default(raw) i32, i64 {
    cell<Cell> = raw.cell
    err<i32>, val<i64> = cell.take_output()
    return err, val
}

// Default vtable.drop_join_handle_slow: drop one ref; dealloc on zero.
fn harness_drop_join_handle_slow_default(raw){
    h<Header> = raw.hdr
    st<State> = h.state
    if st.ref_dec() != 0 {
        vt<RawVTable> = raw.vtable
        fc<vtable_dealloc> = vt.dealloc.(u64)
        fc(raw)
    }
}

// Default vtable.shutdown: set CANCELLED and ensure one schedule kick fires.
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

// Wire harness functions into the default RawVTable. Last writer wins.
func init(){
    raw_vtable_install(
        harness_poll.(u64),
        harness_dealloc_default.(u64),
        harness_try_read_output_default.(u64),
        harness_drop_join_handle_slow_default.(u64),
        harness_shutdown_default.(u64)
    )
}
