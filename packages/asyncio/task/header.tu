// Fixed metadata block at the front of every RawTask.

use runtime

// Schedulers and the harness only access tasks through Header.
mem Header {
    State* life_state
    u64 scheduler                  // raw bits of task.Schedule impl
    runtime.VObjFunc* poll_vtable  // cached from the future header
    RawTask* queue_next            // intrusive next pointer for inject / local queues
    u64 task_id
}

// Return the packed lifecycle / refcount slot.
Header::life_slot() State {
    return this.life_state
}

// Raw scheduler handle bits stored on this header.
Header::sched_bits() u64 {
    return this.scheduler
}

// Snapshot of the packed lifecycle word.
Header::life_load() i32 {
    return this.life_state.load()
}

// Arm the join waker bit; forwards to State.
Header::arm_join_waker() i32 {
    return this.life_state.set_join_waker()
}

// Clear intrusive list link.
Header::clear_queue_next(){
    this.queue_next = null
}

// Link `nxt` after this node in the inject / owned list.
Header::set_queue_next(nxt<RawTask>){
    this.queue_next = nxt
}

// Take the next pointer in the intrusive list.
Header::queue_next_out() RawTask {
    return this.queue_next
}

// Build a fresh Header. Captures fut's VObjFunc* once so the harness does not
// re-read it on every poll.
fn header_new(life_state, scheduler, fut, task_id<u64>) Header {
    f<runtime.Future> = fut.(runtime.Future)
    return new Header {
        life_state: life_state,
        scheduler: scheduler.(u64),
        poll_vtable: f.virf,
        queue_next: null,
        task_id: task_id
    }
}
