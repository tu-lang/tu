// Multi-thread extensions on top of the shared Inject. pop_n_into_local
// drains up to n entries in one lock to amortise contention.

use runtime
use io
use std.atomic
use asyncio.task

// Pull min(n, len) tasks from inj into the worker's Local queue. Returns
// the number of entries actually moved.
//
// Critical: must NOT call push_back_or_overflow while gate_lock is held.
// Local overflow / concurrent-steal spill calls Inject::push, and
// MutexInter is not reentrant — that deadlocked all workers under
// httpserver MT spawn load (Recv-Q stuck, zero epoll_wait).
fn pop_n_into_local(inj<Inject>, n<u32>, local<Local>) u32 {
    if n == 0 return 0

    // Stage raw task bits under the lock, then push into Local unlocked.
    buf<u64*> = runtime.malloc(8 * n.(u64), 1.(i8), 1.(i8))
    taken<u32> = 0

    inj_synced<InjectSynced> = inj.fifo_state
    inj.gate_lock.lock()
    for i<u32> = 0 ; i < n ; i += 1 {
        raw<task.RawTask> = task.task_list_pop_front(&inj_synced.head, &inj_synced.tail)
        if raw == null break
        buf[taken] = raw.(u64)
        taken += 1
    }
    if taken > 0 {
        sh<InjectShared> = inj.depth_atomic
        neg<i32> = 0 - taken.(i32)
        delta<u32> = neg.(u32)
        atomic.xadd(&sh.depth, delta)
    }
    inj.gate_lock.unlock()

    moved<u32> = 0
    for j<u32> = 0 ; j < taken ; j += 1 {
        bits<u64> = buf[j]
        notif<task.Notified> = task.notified_from_raw(bits.(task.RawTask))
        local.push_back_or_overflow(notif, inj)
        moved += 1
    }
    return moved
}
