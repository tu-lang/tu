// block_on root: a Task not registered in OwnedTasks. INITIAL_STATE assumes
// refcount=3 (task + JoinHandle + queue); root has no JoinHandle so we drop one.

// Build a root RawTask wired to sched.
fn bind_root(fut, sched) RawTask {
    tid<TaskId> = alloc_id()
    rtask<RawTask> = raw_new(fut, sched, tid.v)
    rtask.bind_root_unref()
    return rtask
}
