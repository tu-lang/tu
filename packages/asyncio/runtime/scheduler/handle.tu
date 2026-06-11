// Unified scheduler-facing api. Both current_thread and multi_thread.Handle
// implement it so IO Driver park/wake and Builder route through one shape.

// spawn(fut)        : create a Task wrapping fut and schedule its first poll.
// schedule(t)       : enqueue a Notified for the next polling round.
// next_wake_ms() i32: park timeout hint for the IO driver, in milliseconds.
api SchedulerHandle {
    fn spawn(fut)
    fn schedule(t)
    fn next_wake_ms() i32
}
