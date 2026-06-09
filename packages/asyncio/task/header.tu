// Task header: fixed metadata block at the front of every RawTask
// Related: packages-asyncio-runtime task 3.12 / 3.13, R5.1, R5.2
// Design: design §10.2
//
// All RawTask* values point at a Header first.  Schedulers and the harness
// only access tasks through Header to keep the rest of the cell layout
// (output / join slot / future frame) opaque to them.
//
// The schedule field is intentionally typed as `api Schedule`, but since
// task.schedule.tu (task 3.35) is not yet in place this file stores it as a
// dynamic value (`scheduler` field).  Once Schedule is defined, this field
// will be retyped without breaking call sites.

use runtime

mem Header {
    state          // State* (task.state.State pointer)
    scheduler      // api Schedule value; dynamic until task 3.35 lands
    poll_vtable    // VObjFunc* cached from future header
    queue_next     // Header* — intrusive next pointer for inject / local queues
    u64 task_id    // task.TaskId.v
}

// header_new(state, scheduler, fut, task_id): build a fresh Header for a
// brand new task.  poll_vtable is captured from the future's first 8 bytes
// (its VObjFunc*) to avoid re-reading the future header on each poll.
fn header_new(state, scheduler, fut, task_id<u64>) Header {
    h<Header> = new Header
    h.state       = state
    h.scheduler   = scheduler
    // Future objects place their VObjFunc* at offset 0; cast to read it.
    f<runtime.Future> = fut.(runtime.Future)
    h.poll_vtable = f.virf
    h.queue_next  = null
    h.task_id     = task_id
    return h
}
