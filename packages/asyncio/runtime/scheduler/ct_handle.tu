// Cross-call-face handle backing user-visible spawn / spawn_blocking /
// block_on / enter. Implements task.Schedule so harness_complete can
// re-enqueue tasks without knowing which scheduler kind it is on.

use asyncio.task
use asyncio.sync as libsync

// Handle holds the shared state and implements task.Schedule.
mem CtHandle {
    CtShared* shared
}

// Build a handle around shared.
const CtHandle::new(shared<CtShared>) CtHandle {
    h<CtHandle> = new CtHandle
    h.shared = shared
    return h
}

// Schedule a task. Main-thread caller pushes to Core.tasks via the active
// context; external threads push to inject and kick the main loop via
// the woken Notify.
impl task.Schedule for CtHandle {
    fn schedule(t){
        notif<task.Notified> = t
        if is_current_handle(this) {
            ctx<CtContext> = current_ct()
            if ctx != null {
                ctx.core.push_local(notif.raw())
                return
            }
        }
        // Foreign thread or no active context: route through inject.
        this.shared.inject.push(notif)
        libsync.notify_one_raw(this.shared.woken)
    }

    fn release(raw){
        this.shared.owned.remove(raw)
    }
}

// Raw-bits inject lookup for callers outside this package.
fn ct_sched_inject(bits<u64>) Inject* {
    ct<CtHandle> = bits.(CtHandle)
    return ct.shared.inject
}

// Raw-bits spawn entry for callers outside this package.
fn ct_handle_spawn_raw(bits<u64>, fut) task.JoinHandle {
    ct<CtHandle> = bits.(CtHandle)
    return ct_handle_spawn_fut(ct, fut)
}

// Package-level spawn entry (avoids mh.spawn / ct.spawn parser traps).
fn ct_handle_spawn_fut(h<CtHandle>, fut) task.JoinHandle {
    tid<task.TaskId> = task.alloc_id()
    raw<task.RawTask> = task.raw_new(fut, h, tid.v)
    err<i32> = h.shared.owned.bind(raw)
    if err != 0 {
        jh<task.JoinHandle> = new task.JoinHandle
        jh.init(null)
        return jh
    }
    notif<task.Notified> = task.notified_from_raw(raw)
    h.schedule(notif)

    jh2<task.JoinHandle> = new task.JoinHandle
    jh2.init(raw)
    return jh2
}

// Spawn a future as a new task. Wires it into OwnedTasks and schedules
// the first poll. Returns a JoinHandle the caller can await.
// task.raw_new returns a heap RawTask; bind / notified_from_raw take it
// directly (no `&raw` — that would be a stack slot address).
CtHandle::spawn(fut) task.JoinHandle {
    return ct_handle_spawn_fut(this, fut)
}

