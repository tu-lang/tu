// (Header, Cell, Future) view exposed to schedulers via a 5-slot vtable.
// All polymorphism lives in Cell (type assertions), so a single shared
// default vtable suffices.

use runtime

// Function-pointer table. Slots are u64 raw addresses populated by task.harness.
mem RawVTable {
    u64 poll                    // (raw, ctx)
    u64 dealloc                 // (raw)
    u64 try_read_output         // (raw) -> (i32, i64)
    u64 drop_join_handle_slow   // (raw)
    u64 shutdown                // (raw)
}

// Aggregate view used by every scheduler / harness call site.
mem RawTask {
    Header* hdr
    runtime.Future* fut
    Cell* cell
    RawVTable* vtable           // points at the shared default vtable
}

// Module-level singleton; lazily allocated so package init can populate it.
default_vtable<RawVTable*> = null

// Return the shared default vtable singleton, allocating on first call.
fn raw_vtable_default() RawVTable* {
    if default_vtable == null {
        v<RawVTable> = new RawVTable
        v.poll                  = 0
        v.dealloc               = 0
        v.try_read_output       = 0
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
    try_read_output<u64>,
    drop_join_handle_slow<u64>,
    shutdown<u64>
){
    v<RawVTable> = raw_vtable_default()
    v.poll                  = poll
    v.dealloc               = dealloc
    v.try_read_output       = try_read_output
    v.drop_join_handle_slow = drop_join_handle_slow
    v.shutdown              = shutdown
}

// Allocate State + Header + Cell + RawTask wired to the default vtable.
// State starts at INITIAL_STATE (refcount=3, JOIN_INTEREST, NOTIFIED) and
// Cell starts at IDLE.
fn raw_new(fut, scheduler, task_id<u64>) RawTask {
    st<State> = State::new()
    hdr<Header> = header_new(&st, scheduler, fut, task_id)
    cell<Cell> = Cell::new(&hdr, fut)

    raw<RawTask> = new RawTask
    raw.hdr    = &hdr
    raw.fut    = fut
    raw.cell   = &cell
    raw.vtable = raw_vtable_default()
    return raw
}

