// bind_root: build a root RawTask without registering it in OwnedTasks
// Related: packages-asyncio-runtime task 3.36, R14.2
// Design: design §13 / §14 (current_thread.block_on)
//
// block_on() needs a Task wrapper around its top-level future, but that
// task is owned by the caller (not by the scheduler's OwnedTasks list).
// The harness still drives it through the regular vtable path, but no
// remove() should ever fire.  Therefore bind_root() seeds State with a
// refcount of 2 (one for the Notified-style queue entry, one for the
// caller's RawTask*).

use std.atomic

// task.id local state to allocate a fresh root id
fn bind_root(fut, sched) RawTask {
    tid<TaskId> = alloc_id()
    raw<RawTask> = raw_new(fut, sched, tid.v)

    // INITIAL_STATE assumes refcount == 3 (task + JoinHandle + queue).  The
    // root path has no JoinHandle, so drop the count to 2.
    h<Header> = raw.hdr
    st<State> = h.state
    st.ref_dec()
    return raw
}
