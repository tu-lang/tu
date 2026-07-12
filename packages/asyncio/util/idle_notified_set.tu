// Two intrusive lists (idle / notified) for blocking pool workers and JoinSet.
// Nodes embed util.linked_list.Pointers at offset 0 and migrate between lists
// in O(1).

// Holds two LinkedLists; nodes never live on both simultaneously.
mem IdleNotifiedSet {
    LinkedList* idle_q
    LinkedList* notified_q
}

// Build the set with two empty lists.
const IdleNotifiedSet::new() IdleNotifiedSet {
    s<IdleNotifiedSet> = new IdleNotifiedSet
    s.idle_q     = LinkedList::new()
    s.notified_q = LinkedList::new()
    return s
}

// Push a fresh node onto the idle tail. Node must not be on any list yet.
IdleNotifiedSet::insert(node<Pointers>){
    this.idle_q.push_back(node)
}

// Move node from idle -> notified tail. Caller must guarantee node lives on idle.
IdleNotifiedSet::transition_to_notified(node<Pointers>){
    this.idle_q.remove(node)
    this.notified_q.push_back(node)
}

// Move node from notified -> idle tail; the worker uses this after task completion.
IdleNotifiedSet::transition_to_idle(node<Pointers>){
    this.notified_q.remove(node)
    this.idle_q.push_back(node)
}

// Pop the notified head; null when empty.
IdleNotifiedSet::pop_notified() Pointers {
    return this.notified_q.pop_front()
}

// Pop the idle head; null when empty (used during ordered shutdown reclaim).
IdleNotifiedSet::drain_idle() Pointers {
    return this.idle_q.pop_front()
}

// True when both lists are empty.
IdleNotifiedSet::is_empty() i32 {
    ie<i32> = this.idle_q.is_empty()
    ne<i32> = this.notified_q.is_empty()
    if ie != 0 && ne != 0 return 1
    return 0
}
