// Singly-linked intrusive task list helpers; used by inject and OwnedTasks.
// Pure functions — caller serialises access. Empty state == both head/tail null.
// Nodes link via Header.queue_next; queue_next must be null before push.
// head_ptr / tail_ptr are u64* aliases over RawTask* fields so we can update
// them in place without spelling RawTask** (Tu does not support double pointers).

// O(1) append at tail.
fn task_list_push_back(head_ptr<u64*>, tail_ptr<u64*>, raw<RawTask>){
    h<Header> = raw.hdr
    h.queue_next = null
    t_bits<u64> = *tail_ptr
    t<RawTask> = t_bits.(RawTask)
    if t != null {
        prev<Header> = t.hdr
        prev.queue_next = raw
    } else {
        *head_ptr = raw.(u64)
    }
    *tail_ptr = raw.(u64)
}

// O(1) detach + return the head. Returns null when empty; on the last pop
// both head and tail are reset to null.
fn task_list_pop_front(head_ptr<u64*>, tail_ptr<u64*>) RawTask* {
    head_bits<u64> = *head_ptr
    raw<RawTask> = head_bits.(RawTask)
    if raw == null return null
    h<Header> = raw.hdr
    nxt<RawTask> = h.queue_next
    *head_ptr = nxt.(u64)
    if nxt == null {
        *tail_ptr = 0
    }
    h.queue_next = null
    return raw
}

// True when *head_ptr == null.
fn task_list_is_empty(head_ptr<u64*>) bool {
    if *head_ptr == 0 return true
    return false
}

