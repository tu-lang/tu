// Singly-linked intrusive task list helpers; used by inject and OwnedTasks.
// Pure functions — caller serialises access. Empty state == both head/tail null.
// Nodes link via Header.queue_next; queue_next must be null before push.

// O(1) append at tail. head_ptr / tail_ptr are pointers to the host's
// head/tail fields so we can update both in place.
fn task_list_push_back(head_ptr, tail_ptr, raw){
    h<Header> = raw.hdr
    h.queue_next = null
    t = *tail_ptr
    if t != null {
        prev<Header> = t
        prev.queue_next = raw
    } else {
        *head_ptr = raw
    }
    *tail_ptr = raw
}

// O(1) detach + return the head. Returns null when empty; on the last pop
// both head and tail are reset to null.
fn task_list_pop_front(head_ptr, tail_ptr) {
    raw = *head_ptr
    if raw == null return null
    h<Header> = raw.hdr
    nxt = h.queue_next
    *head_ptr = nxt
    if nxt == null {
        *tail_ptr = null
    }
    h.queue_next = null
    return raw
}

// True when *head_ptr == null.
fn task_list_is_empty(head_ptr) bool {
    if *head_ptr == null return true
    return false
}
