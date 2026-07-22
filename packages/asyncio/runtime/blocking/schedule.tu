// Schedule impl that hands BlockingTask completion notifications back to
// the runtime's main scheduler via its inject queue.

use asyncio.task
use asyncio.runtime.scheduler as sched

// BlockingSchedule routes JoinHandle wakes into the runtime's inject.
mem BlockingSchedule {
    sched.Inject* runtime_inject     // back-edge into the main scheduler
}

// Build a BlockingSchedule pointing at runtime_inject.
const BlockingSchedule::new(runtime_inject<sched.Inject>) BlockingSchedule {
    s<BlockingSchedule> = new BlockingSchedule
    s.runtime_inject = runtime_inject
    return s
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

// Bridge fns installed into task Headers (api dispatch on raw Schedule
// bits crashes codegen; the harness calls these plain fn pointers).
fn blocking_schedule_bridge(hbits<u64>, nbits<u64>){
    bs<BlockingSchedule> = hbits.(BlockingSchedule)
    n<task.Notified> = nbits.(task.Notified)
    bs.runtime_inject.push(n)
}

fn blocking_release_bridge(hbits<u64>, rbits<u64>){
    // Blocking tasks are not owner-tracked; nothing to detach.
}

// Export the bridge addresses for cross-package raw_new callers.
fn blocking_sched_bridge_fns() (u64, u64) {
    return blocking_schedule_bridge.(u64), blocking_release_bridge.(u64)
}
