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
    Header* head_meta
    runtime.Future* fut
    Cell* cell
    RawVTable* vt           // points at the shared default vtable
}

// Return the fixed metadata block for this task.
RawTask::meta() Header {
    return this.head_meta
}

// Return the output cell backing this task.
RawTask::cell_ptr() Cell {
    return this.cell
}

// Return the shared vtable pointer.
RawTask::vt_ptr() RawVTable {
    return this.vt
}

// Set CANCELLED and enqueue one wake if needed.
RawTask::abort_signal(){
    life_st<State> = this.head_meta.life_state
    life_st.set_cancelled()
    code<i32> = life_st.transition_to_notified_by_ref()
    if code == TN_Submit {
        sched_bits<u64> = this.head_meta.scheduler
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
        v.read_output       = 0
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
    v.read_output       = read_output
    v.drop_join_handle_slow = drop_join_handle_slow
    v.shutdown              = shutdown
}

// Allocate State + Header + Cell + RawTask wired to the default vtable.
// State starts at INITIAL_STATE (refcount=3, JOIN_INTEREST, NOTIFIED) and
// Cell starts at IDLE.
// Each ::new() already returns a heap pointer, so pass them through
// (no `&st` / `&hdr` — those would be stack-slot addresses).
fn raw_new(fut, scheduler, task_id<u64>) RawTask {
    st<State> = State::new()
    hdr<Header> = header_new(st, scheduler, fut, task_id)
    cell<Cell> = Cell::new(hdr, fut)

    raw<RawTask> = new RawTask
    raw.head_meta = hdr
    raw.fut    = fut
    raw.cell   = cell
    raw.vt = raw_vtable_default()
    return raw
}

