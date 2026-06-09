// TaskId: globally unique task identifier
// Related: packages-asyncio-runtime task 3.1, R8.5
//
// The scheduler assigns each spawned task a strictly increasing, unique u64 id.
// Allocation goes through std.atomic.xadd64 so concurrent allocators never see
// the same value.  TaskId is later packed together with handle_hash into the
// ctx that is propagated to leaf futures (see design §2.7).

use std.atomic

mem TaskId {
    u64 v
}

// Module-level atomic counter; starts at 1 (0 is reserved for "no task")
next_task_id<u64> = 1

// alloc_id(): atomically allocate the next TaskId.
//   xadd64 returns the value AFTER the addition, so the value handed out
//   (the pre-increment value) is `after - 1`.
fn alloc_id() TaskId {
    after<u64> = atomic.xadd64(&next_task_id, 1)
    return new TaskId { v: after - 1 }
}
