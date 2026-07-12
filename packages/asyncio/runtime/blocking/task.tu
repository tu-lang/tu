// Wraps a sync closure as a task that lives on the blocking pool. The
// closure produces a u64 result (raw bits / pointer) which is published
// via the JoinHandle's State + Cell pair.

use asyncio.task

// Caller-provided closure: runs once on a pool worker.
fn blocking_op() (u64)

// Backing structure for one spawn_blocking submission.
mem BlockingTask {
    u64       closure_bits    // raw bits of blocking closure (fn blocking_op)
    RawTask*  task_ptr        // task identity wired to a BlockingSchedule
}

// Build a task that, when run, executes op and stores the u64 result.
const BlockingTask::new(op<u64>, raw<RawTask>) BlockingTask {
    t<BlockingTask> = new BlockingTask
    t.closure_bits = op
    t.task_ptr = raw
    return t
}

// Item enqueued on the pool. mandatory tasks survive shutdown so fs /
// DNS / std-streams paths can flush before the pool tears down.
mem BlockingTaskItem {
    BlockingTask* task
    i32           mandatory     // 0 = drop on shutdown, 1 = run anyway
}

// Build an item wrapping task with the given priority.
const BlockingTaskItem::new(task<BlockingTask>, mandatory<i32>) BlockingTaskItem {
    it<BlockingTaskItem> = new BlockingTaskItem
    it.task      = task
    it.mandatory = mandatory
    return it
}

// Run the closure, publish the result, and drop the run-queue ref.
BlockingTask::run(){
    raw<RawTask> = this.task_ptr
    cell<Cell>   = raw.cell
    cell.transition_to_running()

    // varname<sig> = bits.(u64); see tests/native/fnreturn_cast.tu
    op_fc<blocking_op> = this.closure_bits.(u64)
    val<u64> = op_fc()

    cell.store_output(val.(i64))
    hd<Header> = raw.head_meta
    st<State> = hd.life_state
    st.transition_to_complete()

    // Wake any JoinHandle parked on the result. wake_join_waker no-ops
    // when JOIN_WAKER is unset.
    wake_join_waker(raw)

    // Drop the run-queue ref; dealloc when it was the last one.
    if st.ref_dec() != 0 {
        vt<RawVTable> = raw.vt
        dealloc_fc<vtable_dealloc> = vt.dealloc
        dealloc_fc(raw)
    }
}

