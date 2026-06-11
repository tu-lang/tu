// Fixed metadata block at the front of every RawTask.

use runtime

// Schedulers and the harness only access tasks through Header.
mem Header {
    state          // State*
    scheduler      // api Schedule (typed dynamically until task 3.35 lands)
    poll_vtable    // VObjFunc* cached from the future header
    queue_next     // Header*, intrusive next pointer for inject / local queues
    u64 task_id
}

// Build a fresh Header. Captures fut's VObjFunc* once so the harness does not
// re-read it on every poll.
fn header_new(state, scheduler, fut, task_id<u64>) Header {
    h<Header> = new Header
    h.state       = state
    h.scheduler   = scheduler
    f<runtime.Future> = fut.(runtime.Future)
    h.poll_vtable = f.virf
    h.queue_next  = null
    h.task_id     = task_id
    return h
}
