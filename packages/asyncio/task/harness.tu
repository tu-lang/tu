// Single polling round driver. Schedulers always go through harness_poll;
// it transitions State, invokes the future via VObjFunc.entry, then routes
// PollPending / PollReady / PollError to the right path.

use runtime
use fmt

// Mother: Context carries the task waker. Dynstackcall Future::poll() does
// not forward ctx, so the harness publishes the RawTask* waker here for
// ScheduledIo / sync waiters to register (see resolve_poll_ctx).
ACTIVE_POLL_CTX<u64> = 0

// Prefer the harness-published task waker when the poll arg was null-padded.
fn resolve_poll_ctx(ctx<u64>) u64 {
    if ACTIVE_POLL_CTX != 0 return ACTIVE_POLL_CTX
    return ctx
}

fn active_poll_ctx() u64 {
    return ACTIVE_POLL_CTX
}

// Signature aliases used to cast the u64 vtable slots back to callables.
fn vtable_poll(rtask<RawTask>, ctx<u64>)
fn vtable_dealloc(rtask<RawTask>)
fn vtable_try_read_output_h(rtask<RawTask>) (i32, i64)
fn vtable_drop_join_handle_slow(rtask<RawTask>)
fn vtable_shutdown(rtask<RawTask>)
fn future_poll(fut, ctx<u64>) (i64, i64)

// Run one polling round. ctx packs (scheduler_handle, task_id).
RawTask::harness_poll(ctx<u64>){

    f<runtime.Future> = this.future_ptr
    if f == null {
        f = this.task_cell.fut_store
    }
    if f == null {
        return
    }
    // Future::poll dynstackcall sets up multi-return; passing ctx as an
    // arg corrupts that ABI. Mother still has a Context waker for the
    // task — expose it via ACTIVE_POLL_CTX for IO registration.
    // Stage must be RUNNING for store_output's CAS (IDLE->FINISHED is rejected).
    this.task_cell.force_stage(STAGE_RUNNING)
    prev_ctx<u64> = ACTIVE_POLL_CTX
    ACTIVE_POLL_CTX = ctx
    ready<i64>, output<i64> = f.poll()
    ACTIVE_POLL_CTX = prev_ctx

    if ready == runtime.PollPending {
        this.task_cell.force_stage(STAGE_IDLE)
        return
    }
    // Bypass store_output CAS for now; write slot directly.
    this.task_cell.force_stage(STAGE_FINISHED)
    this.task_cell.write_output_raw(output)
    life_st<TaskState> = this.life_st()
    life_st.force_complete()
}

// Finalise the task: write output, flip COMPLETE, wake join waker, drop ref.
RawTask::harness_complete(err<i32>, output<i64>){
    life_st<TaskState> = this.life_st()
    this.task_cell.store_output(output)
    life_st.transition_to_complete()

    if err != 0 {
        this.task_cell.store_output_err(err)
    }

    this.wake_join_waker()

    if life_st.ref_dec() != 0 {
        this.harness_dealloc()
    }
}

// Idempotent join-waker kick; re-enqueue when JOIN_WAKER was set.
RawTask::wake_join_waker(){
    life_st<TaskState> = this.life_st()
    snap<i32> = life_st.load()
    sched_bits<u64> = 0
    sched<Schedule> = null
    n<Notified> = null
    if (snap & JOIN_WAKER) == 0 return

    life_st.unset_join_waker()

    sched_bits = this.task_header.sched_bits()
    if sched_bits == 0 return
    if this.join_bits() == 0 return
    sched = sched_bits
    n = notified_from_raw(this)
    sched.schedule(n)
}

// Null out cross references on dealloc.
RawTask::harness_dealloc(){
    this.task_header = null
    this.future_ptr  = null
    this.task_cell   = null
    this.vt          = null
}

// Drop one ref; dealloc when it hits zero.
RawTask::drop_join_handle_slow(){
    life_st<TaskState> = this.life_st()
    if life_st.ref_dec() != 0 {
        this.harness_dealloc()
    }
}

// Set CANCELLED and ensure one schedule kick fires.
RawTask::harness_shutdown(){
    life_st<TaskState> = this.life_st()
    life_st.set_cancelled()
    code<i32> = life_st.transition_to_notified_by_ref()
    if code == TN_Submit {
        sched_bits<u64> = this.task_header.sched_bits()
        if sched_bits != 0 {
            sched<Schedule> = sched_bits
            n<Notified> = notified_from_raw(this)
            sched.schedule(n)
        }
    }
}

// Publish blocking-pool result and complete the task.
RawTask::blocking_finish(val<u64>){
    this.task_cell.transition_to_running()
    this.task_cell.store_output(val.(i64))
    life_st<TaskState> = this.life_st()
    life_st.transition_to_complete()
    this.wake_join_waker()
    if life_st.ref_dec() != 0 {
        this.harness_dealloc()
    }
}

// Package-level harness entry used by schedulers.
fn harness_poll(rtask<RawTask>, ctx<u64>){
    rtask.harness_poll(ctx)
}

// Package-level wake helper for blocking pool.
fn wake_join_waker(rtask<RawTask>){
    rtask.wake_join_waker()
}

// Vtable bridges.
fn harness_poll_vtable(rtask<RawTask>, ctx<u64>){
    rtask.harness_poll(ctx)
}

fn harness_dealloc_vtable(rtask<RawTask>){
    rtask.harness_dealloc()
}

fn harness_try_read_output_vtable(rtask<RawTask>) i32, i64 {
    err<i32> = 0
    val<i64> = 0
    err, val = rtask.take_cell_output()
    return err, val
}

fn harness_drop_join_slow_vtable(rtask<RawTask>){
    rtask.drop_join_handle_slow()
}

fn harness_shutdown_vtable(rtask<RawTask>){
    rtask.harness_shutdown()
}

// Wire harness functions into the default RawVTable.
func init(){
    raw_vtable_install(
        harness_poll_vtable.(u64),
        harness_dealloc_vtable.(u64),
        harness_try_read_output_vtable.(u64),
        harness_drop_join_slow_vtable.(u64),
        harness_shutdown_vtable.(u64)
    )
}
