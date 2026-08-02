// Singly-linked intrusive task list helpers; used by inject / local queues
// only (Header.queue_next). OwnedTasks uses Header.owned_* (see owned.tu).
// Pure functions — caller serialises access. Empty state == both head/tail null.

// O(1) append at tail.
fn task_list_push_back(head_ptr<u64*>, tail_ptr<u64*>, rtask<RawTask>){
    rtask.list_prep_push()
    t_bits<u64> = *tail_ptr
    tail_task<RawTask> = t_bits.(RawTask)
    if tail_task != null {
        tail_task.list_link_next(rtask)
    } else {
        *head_ptr = rtask.(u64)
    }
    *tail_ptr = rtask.(u64)
}

// O(1) detach + return the head. Returns null when empty.
fn task_list_pop_front(head_ptr<u64*>, tail_ptr<u64*>) RawTask {
    head_bits<u64> = *head_ptr
    rtask<RawTask> = head_bits.(RawTask)
    if rtask == null return null
    nxt_task<RawTask> = rtask.list_take_next()
    *head_ptr = nxt_task.(u64)
    if nxt_task == null {
        *tail_ptr = 0
    }
    rtask.list_prep_push()
    return rtask
}

// True when *head_ptr == null.
fn task_list_is_empty(head_ptr<u64*>) i32 {
    if *head_ptr == 0 return 1
    return 0
}
