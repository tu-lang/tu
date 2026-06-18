// Cross-call-face handle backing user-visible spawn / spawn_blocking /
// block_on / enter. Implements task.Schedule so harness_complete can
// re-enqueue tasks without knowing which scheduler kind it is on.

use asyncio.task

// Handle holds the shared state and implements task.Schedule.
mem CtHandle {
    CtShared* shared
}

// Build a handle around shared.
const CtHandle::new(shared<CtShared>) CtHandle* {
    h<CtHandle> = new CtHandle
    h.shared = shared
    return &h
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
                ctx.core.push_local(notif.raw)
                return
            }
        }
        // Foreign thread or no active context: route through inject.
        this.shared.inject.push(notif)
        this.shared.woken.notify_one()
    }

    fn release(raw){
        this.shared.owned.remove(raw)
    }
}

// Spawn a future as a new task. Wires it into OwnedTasks and schedules
// the first poll. Returns a JoinHandle the caller can await.
CtHandle::spawn(fut) JoinHandle* {
    tid<task.TaskId> = task.alloc_id()
    raw<task.RawTask> = task.raw_new(fut, this, tid.v)
    err<i32> = this.shared.owned.bind(&raw)
    if err != 0 {
        // OwnedTasks::bind already rejects with RuntimeShutdown; surface
        // a JoinHandle whose first poll observes the empty raw slot.
        jh<JoinHandle> = new JoinHandle
        jh.init(null)
        return &jh
    }
    notif<task.Notified> = task.notified_from_raw(&raw)
    this.schedule(notif)

    jh<JoinHandle> = new JoinHandle
    jh.init(&raw)
    return &jh
}

