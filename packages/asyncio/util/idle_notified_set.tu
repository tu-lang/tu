// IdleNotifiedSet: split nodes between two intrusive lists, idle and notified
// Related: packages-asyncio-runtime task 2.9 / 2.10, R29.1
// Design: design §25.4
//
// Shared by the runtime.blocking pool's worker_threads and sync.JoinSet.
// Nodes embed util.linked_list.Pointers at offset 0 so they can move between
// the two lists in O(1).
//   - insert(node): default to pushing onto the idle tail
//   - transition_to_notified(node): unlink from idle, push onto notified tail
//   - pop_notified() Pointers*: take one from the notified head; null when empty
//   - drain_idle() Pointers*: pop the idle head; null when empty (used during
//     ordered shutdown reclaim)

use std

class IdleNotifiedSet {
    idle      // util.linked_list.LinkedList
    notified  // util.linked_list.LinkedList
}

IdleNotifiedSet::init(){
    this.idle = new linked_list.LinkedList
    this.idle.init()
    this.notified = new linked_list.LinkedList
    this.notified.init()
}

// insert(node): push a fresh node onto the idle tail.
//   The node must not currently belong to any list (prev/next == null).
IdleNotifiedSet::insert(node<linked_list.Pointers*>){
    this.idle.push_back(node)
}

// transition_to_notified(node): unlink from idle, push onto notified tail.
//   Caller must guarantee node currently lives on this.idle. O(1).
IdleNotifiedSet::transition_to_notified(node<linked_list.Pointers*>){
    this.idle.remove(node)
    this.notified.push_back(node)
}

// transition_to_idle(node): inverse of transition_to_notified.
//   The blocking pool calls it after a worker finishes processing a task.
IdleNotifiedSet::transition_to_idle(node<linked_list.Pointers*>){
    this.notified.remove(node)
    this.idle.push_back(node)
}

// pop_notified(): take a node from the notified head; null when empty
IdleNotifiedSet::pop_notified() linked_list.Pointers* {
    return this.notified.pop_front()
}

// drain_idle(): take a node from the idle head; null when empty.
//   During shutdown the caller loops on it to drain idle entirely.
IdleNotifiedSet::drain_idle() linked_list.Pointers* {
    return this.idle.pop_front()
}

// is_empty(): both lists empty
IdleNotifiedSet::is_empty() bool {
    if this.idle.is_empty() && this.notified.is_empty() return true
    return false
}
