// (Header, Cell, Future) view exposed to schedulers via a 5-slot vtable.
// All polymorphism lives in Cell (type assertions), so a single shared
// default vtable suffices.

use runtime
use fmt

// Function-pointer table. Slots are u64 raw addresses populated by task.harness.
mem RawVTable {
    u64 poll                    // (raw, ctx)
    u64 dealloc                 // (raw)
    u64 read_output             // (raw) -> (i32, i64)
    u64 drop_join_handle_slow   // (raw)
    u64 shutdown                // (raw)
}

// Aggregate view used by every scheduler / harness call site.
mem RawTask {
    Header* task_header
    runtime.Future* future_ptr
    Cell* task_cell
    RawVTable* vt
}

// Drop one ref for block_on root (no JoinHandle).
RawTask::bind_root_unref(){
    h<Header> = this.task_header
    st<TaskState> = h.life_slot()
    st.ref_dec()
}

// Stash join ctx and arm JOIN_WAKER. Returns set_join_waker code.
RawTask::register_join_waker(ctx<u64>) i32 {
    this.task_cell.write_packed_waker(ctx)
    return this.task_header.arm_join_waker()
}

// Read packed join-waker ctx from the task cell.
RawTask::join_bits() u64 {
    return this.task_cell.read_packed_waker()
}

// Lifecycle snapshot for JoinHandle::poll.
RawTask::life_load() i32 {
    return this.task_header.life_load()
}

// Return the lifecycle State slot for this task.
RawTask::life_st() TaskState {
    return this.task_header.life_slot()
}

// Read output from the task cell (vtable try_read_output slot).
RawTask::take_cell_output() (i32, i64) {
    err<i32> = 0
    val<i64> = 0
    err, val = this.task_cell.take_output()
    return err, val
}

// Read output via the shared vtable slot.
// Direct call — fn-pointer multi-return codegen drops/corrupts results.
RawTask::read_output() (i32, i64) {
    err<i32> = 0
    val<i64> = 0
    err, val = this.take_cell_output()
    return err, val
}

// Intrusive-list helpers (inject / OwnedTasks).
RawTask::list_prep_push(){
    this.task_header.clear_queue_next()
}

RawTask::list_link_next(nxt<RawTask>){
    this.task_header.set_queue_next(nxt)
}

RawTask::list_take_next() RawTask {
    return this.task_header.queue_next_out()
}

// Set NOTIFIED and enqueue when needed.
RawTask::wake_by_ref(){
    raw_wake_by_ref_bits(this.(u64))
}

// Package-fn wake used by wake_by_ctx.
fn raw_wake_by_ref_bits(ctx<u64>) {
    if ctx == 0 {
        return
    }
    rtask<RawTask> = null
    rtask = ctx
    life_st<TaskState> = rtask.life_st()
    code<i32> = life_st.transition_to_notified_by_ref()
    if code == TN_Submit {
        n<Notified> = notified_from_raw(rtask)
        rtask.task_header.sched_schedule(n)
    }
}

// Wake from a packed ctx that holds RawTask*.
fn wake_by_ctx(ctx<u64>){
    raw_wake_by_ref_bits(ctx)
}

// Set CANCELLED and enqueue one wake if needed.
RawTask::abort_signal(){
    life_st<TaskState> = this.life_st()
    life_st.set_cancelled()
    this.wake_by_ref()
}

// Module-level singleton; lazily allocated so package init can populate it.
default_vtable<RawVTable> = null

// Return the shared default vtable singleton, allocating on first call.
fn raw_vtable_default() RawVTable {
    if default_vtable == null {
        v<RawVTable> = new RawVTable
        v.poll                  = 0
        v.dealloc               = 0
        v.read_output           = 0
        v.drop_join_handle_slow = 0
        v.shutdown              = 0
        default_vtable = v
    }
    return default_vtable
}

// Wire concrete function addresses into the default vtable; called once by
// task.harness's `init()`.
fn raw_vtable_install(
    poll<u64>,
    dealloc<u64>,
    read_output<u64>,
    drop_join_handle_slow<u64>,
    shutdown<u64>
){
    v<RawVTable> = raw_vtable_default()
    v.poll                  = poll
    v.dealloc               = dealloc
    v.read_output           = read_output
    v.drop_join_handle_slow = drop_join_handle_slow
    v.shutdown              = shutdown
}

// Allocate TaskState + Header + Cell + RawTask wired to the default vtable.
// sched_fn / rel_fn: scheduler bridge fn pointers (see Header).
fn raw_new(fut_bits<u64>, scheduler, sched_fn<u64>, rel_fn<u64>, task_id<u64>) RawTask {
    fut<runtime.Future> = fut_bits.(runtime.Future)
    if fut == null {
    } else {
    }
    st<TaskState> = TaskState::new()
    hdr<Header> = header_new(st, scheduler, sched_fn, rel_fn, fut, task_id)
    cell<Cell> = Cell::new(hdr, fut)

    rtask<RawTask> = new RawTask
    rtask.task_header = hdr
    rtask.future_ptr  = fut
    rtask.task_cell   = cell
    rtask.vt          = raw_vtable_default()
    if rtask.future_ptr == null {
    } else {
    }
    return rtask
}

// Signature alias for casting RawVTable.read_output back to a callable.
fn vtable_try_read_output(rtask) (i32, i64)
