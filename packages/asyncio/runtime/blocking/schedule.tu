// Schedule impl for blocking-pool tasks. schedule() is never used
// (blocking tasks are not futures re-polled by the runtime); release()
// is a no-op outside test-util clock bookkeeping.

use asyncio.task

// NoopSchedule — unowned blocking task scheduler.
mem BlockingSchedule {
    i32 _pad
}

// Build a NoopSchedule stand-in for unowned blocking tasks.
const BlockingSchedule::new() BlockingSchedule {
    return new BlockingSchedule
}

// Schedule for BlockingSchedule: schedule is unreachable — joining
// waiters wake via the awaiter's own Schedule (CtHandle/MtHandle).
impl task.Schedule for BlockingSchedule {
    fn schedule(t){
        // Blocking tasks are not re-scheduled by the runtime.
    }
    fn release(raw){
        // No owned-list detach; test-util may unpark clock.
    }
}

// Bridge fns installed into task Headers (api dispatch on raw Schedule
// bits crashes codegen; the harness calls these plain fn pointers).
fn blocking_schedule_bridge(hbits<u64>, nbits<u64>){
    // NoopSchedule::schedule is never invoked.
}

fn blocking_release_bridge(hbits<u64>, rbits<u64>){
    // Blocking tasks are not owner-tracked; nothing to detach.
}

// Export the bridge addresses for cross-package raw_new callers.
fn blocking_sched_bridge_fns() (u64, u64) {
    return blocking_schedule_bridge.(u64), blocking_release_bridge.(u64)
}
