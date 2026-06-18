// Schedule impl that hands BlockingTask completion notifications back to
// the runtime's main scheduler via its inject queue.

use asyncio.task
use asyncio.runtime.scheduler

// BlockingSchedule routes JoinHandle wakes into the runtime's inject.
mem BlockingSchedule {
    Inject* runtime_inject     // back-edge into the main scheduler
}

// Build a BlockingSchedule pointing at runtime_inject.
const BlockingSchedule::new(runtime_inject<Inject>) BlockingSchedule* {
    s<BlockingSchedule> = new BlockingSchedule
    s.runtime_inject = runtime_inject
    return &s
}

// Implement the Schedule contract: forward Notified into the runtime's
// inject queue, and let release() detach from any owner-tracking layer.
impl task.Schedule for BlockingSchedule {
    fn schedule(t){
        notif<task.Notified> = t
        this.runtime_inject.push(notif)
    }
    fn release(raw){
        // Blocking tasks are not tracked by an OwnedTasks list — they're
        // ephemeral submissions. Nothing to detach here.
    }
}

