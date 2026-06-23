// Scheduler contract every Task owner implements.

// schedule(t) : enqueue a Notified into the run queue.
// release(raw): detach raw from owner-tracking structures on final ref drop.
api Schedule {
    fn schedule(t)
    fn release(raw)
}
