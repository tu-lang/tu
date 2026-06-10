// RawTask: vtable view over (Header, Cell, Future)
// Related: packages-asyncio-runtime task 3.17 / 3.18, R5.4, R5.5
// Design: design §10.4
//
// The harness and schedulers only see RawTask; they never touch the inner
// Cell or Future directly.  RawVTable holds the five function pointers that
// drive the task lifecycle:
//   poll                  : run one polling round (called by harness)
//   dealloc               : free the task allocation when ref count hits 0
//   try_read_output       : read the cached output, used by JoinHandle
//   drop_join_handle_slow : slow path when JoinHandle is dropped before take
//   shutdown              : cancel + cleanup on runtime shutdown
//
// All five are stored as u64 raw addresses; concrete implementations live in
// task.harness (default vtable) and may be overridden by specialised paths.

mem RawVTable {
    u64 poll
    u64 dealloc
    u64 try_read_output
    u64 drop_join_handle_slow
    u64 shutdown
}

mem RawTask {
    hdr        // Header*
    fut        // runtime.Future*
    cell       // Cell*
    vtable     // RawVTable*
}

// Module-level default vtable singleton; populated lazily in raw_vtable_default()
// once the harness module fills in the function pointers.
//
// The default vtable is a single shared instance because all polymorphic
// behaviour lives inside Cell / Header (handled by type assertions), so every
// task can share the same five entry points (R5.4 — task harness §10.5).
default_vtable<RawVTable*> = null

// raw_vtable_default(): return the shared default vtable singleton.
//   The five fields stay 0 until task.harness wires them up via
//   `raw_vtable_install(...)`.  Callers always read through this getter so
//   later calls see the wired vtable atomically.
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

// raw_vtable_install(poll, dealloc, try_read_output, drop_join_handle_slow, shutdown):
//   Called once by task.harness during package init to populate the default
//   vtable with concrete function addresses.  Re-installation overwrites the
//   slots; specialised tasks can build their own RawVTable instead.
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

// raw_new(fut, scheduler, task_id): build a fresh RawTask wired to the
// default vtable.
//   Allocates a State + Header + Cell, sets State to INITIAL_STATE (refcount
//   == 3, JOIN_INTEREST, NOTIFIED), and caches the future's poll vtable.
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
