// Fixed metadata block at the front of every RawTask.

use runtime

// Schedulers and the harness only access tasks through Header.
mem Header {
    TaskState* lifecycle
    u64 scheduler                  // raw bits of task.Schedule impl
    u64 sched_schedule_fn          // bridge fn(hbits, Notified); api dispatch on bits crashes codegen
    u64 sched_release_fn           // bridge fn(hbits, RawTask)
    runtime.VObjFunc* poll_vtable  // cached from the future header
    RawTask* queue_next            // intrusive next pointer for inject / local queues
    u64 task_id
}

// Signature aliases for the scheduler bridge slots (all-u64 args).
fn sched_schedule_sig(hbits<u64>, nbits<u64>)
fn sched_release_sig(hbits<u64>, rbits<u64>)

// Submit a Notified through the scheduler bridge. Assigning raw bits to a
// `Schedule` api variable and dispatching crashes codegen (repair-plan §7),
// so schedulers register a plain fn pointer instead.
Header::sched_schedule(n<Notified>){
    if this.scheduler == 0 { return }
    slot<u64> = this.sched_schedule_fn
    if slot == 0 { return }
    nbits<u64> = 0
    nbits = n
    op_fc<sched_schedule_sig> = slot.(u64)
    op_fc(this.scheduler, nbits)
}

// Release this task from the scheduler's owner list via the bridge fn.
Header::sched_release(rtask<RawTask>){
    if this.scheduler == 0 { return }
    slot<u64> = this.sched_release_fn
    if slot == 0 { return }
    rbits<u64> = 0
    rbits = rtask
    op_fc<sched_release_sig> = slot.(u64)
    op_fc(this.scheduler, rbits)
}

// Return the packed lifecycle / refcount slot.
Header::life_slot() TaskState {
    return this.lifecycle
}

// Raw scheduler handle bits stored on this header.
Header::sched_bits() u64 {
    return this.scheduler
}

// Snapshot of the packed lifecycle word.
Header::life_load() i32 {
    return this.lifecycle.load()
}

// Arm the join waker bit; forwards to State.
Header::arm_join_waker() i32 {
    return this.lifecycle.set_join_waker()
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
// re-read it on every poll. sched_fn / rel_fn are the scheduler bridge fns.
fn header_new(lifecycle, scheduler, sched_fn<u64>, rel_fn<u64>, fut, task_id<u64>) Header {
    f<runtime.Future> = fut.(runtime.Future)
    return new Header {
        lifecycle: lifecycle,
        scheduler: scheduler.(u64),
        sched_schedule_fn: sched_fn,
        sched_release_fn: rel_fn,
        poll_vtable: f.virf,
        queue_next: null,
        task_id: task_id
    }
}
