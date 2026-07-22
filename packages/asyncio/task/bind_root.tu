// block_on root: a Task not registered in OwnedTasks. INITIAL_STATE assumes
// refcount=3 (task + JoinHandle + queue); root has no JoinHandle so we drop one.

// Build a root RawTask wired to sched. fut_bits is Future* as u64
// (cross-pkg dynamic fut args are dropped by codegen).
fn bind_root(fut_bits<u64>, sched, sched_fn<u64>, rel_fn<u64>) RawTask {
    tid<TaskId> = alloc_id()
    rtask<RawTask> = raw_new(fut_bits, sched, sched_fn, rel_fn, tid.v)
    // Root has no JoinHandle: mother drops one ref here. Temporarily
    // deferred — TaskState::ref_dec via life_slot still under investigation.
    // rtask.bind_root_unref()
    return rtask
}
