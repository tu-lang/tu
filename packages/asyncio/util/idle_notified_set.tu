// Two intrusive lists (idle / notified) for blocking pool workers and JoinSet.
// Nodes embed util.linked_list.Pointers at offset 0 and migrate between lists
// in O(1).

use std

// Holds two LinkedLists; nodes never live on both simultaneously.
class IdleNotifiedSet {
    idle      // util.linked_list.LinkedList
    notified  // util.linked_list.LinkedList
}

// Create both lists in their empty state.
IdleNotifiedSet::init(){
    this.idle = new linked_list.LinkedList
    this.idle.init()
    this.notified = new linked_list.LinkedList
    this.notified.init()
}

// Push a fresh node onto the idle tail. Node must not be on any list yet.
IdleNotifiedSet::insert(node<linked_list.Pointers*>){
    this.idle.push_back(node)
}

// Move node from idle -> notified tail. Caller must guarantee node lives on idle.
IdleNotifiedSet::transition_to_notified(node<linked_list.Pointers*>){
    this.idle.remove(node)
    this.notified.push_back(node)
}

// Move node from notified -> idle tail; the worker uses this after task completion.
IdleNotifiedSet::transition_to_idle(node<linked_list.Pointers*>){
    this.notified.remove(node)
    this.idle.push_back(node)
}

// Pop the notified head; null when empty.
IdleNotifiedSet::pop_notified() linked_list.Pointers* {
    return this.notified.pop_front()
}

// Pop the idle head; null when empty (used during ordered shutdown reclaim).
IdleNotifiedSet::drain_idle() linked_list.Pointers* {
    return this.idle.pop_front()
}

// True when both lists are empty.
IdleNotifiedSet::is_empty() bool {
    if this.idle.is_empty() && this.notified.is_empty() return true
    return false
}
