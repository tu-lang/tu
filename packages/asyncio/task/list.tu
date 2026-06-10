// Intrusive task list helpers
// Related: packages-asyncio-runtime task 3.28, R10.1
// Design: design §11 (inject), §10.6 (OwnedTasks)
//
// These helpers operate on a single-linked, intrusive list keyed by
// `Header.queue_next`.  Both inject queues and OwnedTasks reach for them so
// the Header layout is the only contract the queue/owned implementations
// need to know about.  Helpers are pure functions; callers handle locking.
//
// Layout requirement: the host structure exposes two `Header*` fields, head
// and tail, both null when empty.  Adding a node requires the node's
// queue_next to be null on entry.

// task_list_push_back(head_ptr, tail_ptr, raw): O(1) append.
//   `head_ptr` and `tail_ptr` are pointers to the host's head/tail fields so
//   we can update them in place.  The node's queue_next is reset to null.
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

// task_list_pop_front(head_ptr, tail_ptr): O(1) detach + return the head.
//   Returns null when the list is empty.  Updates both head and tail to keep
//   the empty-state invariant (both null) intact.
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

// task_list_is_empty(head_ptr): true when head is null.
fn task_list_is_empty(head_ptr) bool {
    if *head_ptr == null return true
    return false
}
