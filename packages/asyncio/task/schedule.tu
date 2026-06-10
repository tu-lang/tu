// Task scheduler contract
// Related: packages-asyncio-runtime task 3.35, R5.1
// Design: design §10 / §13 / §16
//
// Every scheduler that owns a Task must implement Schedule:
//   - schedule(t)  : enqueue a Notified task into its run queue (the harness
//                    transition path calls this when transition_to_notified
//                    returns Submit).
//   - release(raw) : detach a RawTask from any owner-tracking structures
//                    (OwnedTasks for current_thread / multi_thread) when the
//                    final reference is dropped.
//
// current_thread.Handle, multi_thread.Handle, and runtime.blocking.BlockingSchedule
// each provide a concrete impl.  Header.scheduler is typed as `api Schedule`
// once this file is in place.

api Schedule {
    fn schedule(t)
    fn release(raw)
}
