// Wraps a sync closure as a task that lives on the blocking pool. The
// closure produces a u64 result (raw bits / pointer) which is published
// via the JoinHandle's State + Cell pair.

use asyncio.task

// Caller-provided closure: runs once on a pool worker.
fn blocking_op() (u64)

// Backing structure for one spawn_blocking submission.
mem BlockingTask {
    u64            closure_bits    // raw bits of blocking closure (fn blocking_op)
    task.RawTask*  task_ptr        // task identity wired to a BlockingSchedule
}

// Build a task that, when run, executes op and stores the u64 result.
const BlockingTask::new(op<u64>, raw<task.RawTask>) BlockingTask {
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
const BlockingTaskItem::new(task_obj<BlockingTask>, mandatory<i32>) BlockingTaskItem {
    it<BlockingTaskItem> = new BlockingTaskItem
    it.task      = task_obj
    it.mandatory = mandatory
    return it
}

// Run the closure, publish the result, and drop the run-queue ref.
BlockingTask::run(){
    rtask<task.RawTask> = this.task_ptr
    bits<u64> = this.closure_bits
    op_fc<blocking_op> = bits.(u64)
    val<u64> = op_fc()
    rtask.blocking_finish(val)
}
