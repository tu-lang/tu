// Globally unique task id. 0 reserved for "no task"; counter starts at 1.

use std.atomic

// Wraps the u64 counter value handed to a freshly spawned task.
mem TaskId {
    u64 v
}

next_task_id<u64> = 1

// Atomically allocate the next id; xadd64 returns the post-increment value
// so the caller-visible id is `after - 1`.
fn alloc_id() TaskId {
    after<u64> = atomic.xadd64(&next_task_id, 1)
    return new TaskId { v: after - 1 }
}
