// Single polling round driver. Schedulers always go through harness_poll;
// it transitions State, invokes the future via VObjFunc.entry, then routes
// PollPending / PollReady / PollError to the right path.

use runtime

// Prefer the harness-published task waker when the poll arg was null-padded.
// Per-Core slot (poll_ctx.tu) — process-global ACTIVE_POLL_CTX races under MT.
fn resolve_poll_ctx(ctx<u64>) u64 {
    active<u64> = poll_ctx_get()
    if active != 0 {
        return active
    }
    return ctx
}

fn active_poll_ctx() u64 {
    return poll_ctx_get()
}

// Signature aliases used to cast the u64 vtable slots back to callables.
fn vtable_poll(rtask<RawTask>, ctx<u64>)
fn vtable_dealloc(rtask<RawTask>)
fn vtable_try_read_output_h(rtask<RawTask>) (i32, i64)
fn vtable_drop_join_handle_slow(rtask<RawTask>)
fn vtable_shutdown(rtask<RawTask>)
fn future_poll(fut, ctx<u64>) (i64, i64)

// Run one polling round. ctx packs the
// task waker (RawTask* bits). All lifecycle moves go through TaskState.
RawTask::harness_poll(ctx<u64>){
    life_st<TaskState> = this.life_st()
    tr<i32> = life_st.transition_to_running()
    if tr == TR_Cancelled {
        // CANCELLED was set before this poll; RUNNING is held, finish now.
        this.task_cell.force_stage(STAGE_RUNNING)
        this.harness_complete(JoinErrorCancelled, 0)
        return
    }
    if tr == TR_Dealloc {
        this.harness_dealloc()
        return
    }
    if tr != TR_Success {
        return
    }

    f<runtime.Future> = this.future_ptr
    if f == null {
        f = this.task_cell.fut_store
    }
    if f == null {
        this.task_cell.force_stage(STAGE_RUNNING)
        this.harness_complete(JoinErrorRuntimePollError, 0)
        return
    }
    // Future::poll dynstackcall sets up multi-return; passing ctx as an
    // arg corrupts that ABI. Publish per-Core so MT workers do not clobber
    // each other (global ACTIVE_POLL_CTX caused hang via wrong join waker).
    // Stage must be RUNNING for store_output's CAS (IDLE->FINISHED is rejected).
    this.task_cell.force_stage(STAGE_RUNNING)
    prev_ctx<u64> = poll_ctx_set(ctx)
    ready<i32>, output<i64> = f.poll()
    poll_ctx_set(prev_ctx)

    if ready == runtime.PollPending {
        ti<i32> = life_st.transition_to_idle()
        if ti == TI_Cancelled {
            // Cancelled during the poll; stage is still RUNNING.
            this.harness_complete(JoinErrorCancelled, 0)
            return
        }
        this.task_cell.force_stage(STAGE_IDLE)
        if ti == TI_OkNotified {
            // Self-wake fired mid-poll: submit the fresh Notified ref taken
            // by transition_to_idle, then drop our own poll ref.
            n<Notified> = notified_from_raw(this)
            this.task_header.sched_schedule(n)
            // Schedule may only unpark (block_on root) and leave NOTIFIED set;
            // clear the bit so the next direct poll goes through prepare.
            life_st.clear_notified_bit()
            if life_st.ref_dec() != 0 {
                this.harness_dealloc()
            }
            return
        }
        if ti == TI_OkDealloc {
            this.harness_dealloc()
        }
        return
    }
    if ready == runtime.PollError {
        this.harness_complete(JoinErrorRuntimePollError, output)
        return
    }
    this.harness_complete(0, output)
}

// Finalise the task: write output, flip
// COMPLETE, wake the JoinHandle waker, release from the owner list, then
// drop the poll ref. Assumes lifecycle RUNNING and cell stage RUNNING.
RawTask::harness_complete(err<i32>, output<i64>){
    life_st<TaskState> = this.life_st()
    this.task_cell.store_output(output)
    if err != 0 {
        this.task_cell.store_output_err(err)
    }
    snap<i32> = life_st.transition_to_complete()

    if (snap & JOIN_INTEREST) != 0 {
        this.wake_join_waker()
    }

    // The design release(): detach from the scheduler's OwnedTasks.
    this.task_header.sched_release(this)

    if life_st.ref_dec() != 0 {
        this.harness_dealloc()
    }
}

// Wake the JoinHandle waker registered in the cell.
// Must NOT re-schedule this (completed) task; it wakes the joining task.
RawTask::wake_join_waker(){
    life_st<TaskState> = this.life_st()
    snap<i32> = life_st.load()
    if (snap & JOIN_WAKER) == 0 { return }

    life_st.unset_join_waker()

    jb<u64> = this.join_bits()
    if jb == 0 { return }
    wake_by_ctx(jb)
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
        n<Notified> = notified_from_raw(this)
        this.task_header.sched_schedule(n)
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
