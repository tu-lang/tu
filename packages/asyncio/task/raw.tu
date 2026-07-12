// (Header, Cell, Future) view exposed to schedulers via a 5-slot vtable.
// All polymorphism lives in Cell (type assertions), so a single shared
// default vtable suffices.

use runtime

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
    this.task_header.life_slot().ref_dec()
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
RawTask::life_st() State {
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
RawTask::read_output() (i32, i64) {
    vt<RawVTable> = this.vt
    read_fc<vtable_try_read_output> = vt.read_output
    err<i32> = 0
    val<i64> = 0
    err, val = read_fc(this)
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

// Set CANCELLED and enqueue one wake if needed.
RawTask::abort_signal(){
    life_st<State> = this.life_st()
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

// Allocate State + Header + Cell + RawTask wired to the default vtable.
fn raw_new(fut, scheduler, task_id<u64>) RawTask {
    st<State> = State::new()
    hdr<Header> = header_new(st, scheduler, fut, task_id)
    cell<Cell> = Cell::new(hdr, fut)

    rtask<RawTask> = new RawTask
    rtask.task_header = hdr
    rtask.future_ptr  = fut
    rtask.task_cell   = cell
    rtask.vt          = raw_vtable_default()
    return rtask
}

// Signature alias for casting RawVTable.read_output back to a callable.
fn vtable_try_read_output(rtask) (i32, i64)
