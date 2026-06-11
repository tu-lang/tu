// block_on root: a Task not registered in OwnedTasks. INITIAL_STATE assumes
// refcount=3 (task + JoinHandle + queue); root has no JoinHandle so we drop one.

use std.atomic

// Build a root RawTask wired to sched.
fn bind_root(fut, sched) RawTask {
    tid<TaskId> = alloc_id()
    raw<RawTask> = raw_new(fut, sched, tid.v)
    h<Header> = raw.hdr
    st<State> = h.state
    st.ref_dec()
    return raw
}
