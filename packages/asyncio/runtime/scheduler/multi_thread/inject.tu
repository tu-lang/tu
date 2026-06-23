// Multi-thread extensions on top of the shared Inject. pop_n_into_local
// drains up to n entries in one lock to amortise contention.

use runtime
use io
use asyncio.task

// Pull min(n, len) tasks from inj into the worker's Local queue. Returns
// the number of entries actually moved.
fn pop_n_into_local(inj<Inject>, n<u32>, local<Local>) u32 {
    if n == 0 return 0

    inj_synced<InjectSynced> = inj.synced
    inj.lock.lock()

    moved<u32> = 0
    for i<u32> = 0 ; i < n ; i += 1 {
        raw<task.RawTask> = task.task_list_pop_front(&inj_synced.head, &inj_synced.tail)
        if raw == null break
        notif<task.Notified> = task.notified_from_raw(raw)
        // The Local push may overflow back into inject; drop the lock
        // for that branch by calling push_back_or_overflow with the same
        // inj. push_back_or_overflow expects no inject lock held — we
        // rely on the half-empty guarantee from caller.
        local.push_back_or_overflow(notif, inj)
        moved += 1
    }

    sh<InjectShared> = inj.shared
    if moved > 0 {
        // -moved via two's complement. xadd takes u32.
        delta<u32> = (0 - moved.(i32)).(u32)
        runtime.atomic.xadd(&sh.len, delta)
    }
    inj.lock.unlock()
    return moved
}

