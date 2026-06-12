// Two intrusive lists (idle / notified) for blocking pool workers and JoinSet.
// Nodes embed util.linked_list.Pointers at offset 0 and migrate between lists
// in O(1).

// Holds two LinkedLists; nodes never live on both simultaneously.
mem IdleNotifiedSet {
    LinkedList* idle
    LinkedList* notified
}

// Build the set with two empty lists.
const IdleNotifiedSet::new() IdleNotifiedSet* {
    s<IdleNotifiedSet> = new IdleNotifiedSet
    s.idle     = LinkedList::new()
    s.notified = LinkedList::new()
    return s
}

// Push a fresh node onto the idle tail. Node must not be on any list yet.
IdleNotifiedSet::insert(node<Pointers*>){
    this.idle.push_back(node)
}

// Move node from idle -> notified tail. Caller must guarantee node lives on idle.
IdleNotifiedSet::transition_to_notified(node<Pointers*>){
    this.idle.remove(node)
    this.notified.push_back(node)
}

// Move node from notified -> idle tail; the worker uses this after task completion.
IdleNotifiedSet::transition_to_idle(node<Pointers*>){
    this.notified.remove(node)
    this.idle.push_back(node)
}

// Pop the notified head; null when empty.
IdleNotifiedSet::pop_notified() Pointers* {
    return this.notified.pop_front()
}

// Pop the idle head; null when empty (used during ordered shutdown reclaim).
IdleNotifiedSet::drain_idle() Pointers* {
    return this.idle.pop_front()
}

// True when both lists are empty.
IdleNotifiedSet::is_empty() bool {
    if this.idle.is_empty() && this.notified.is_empty() return true
    return false
}

