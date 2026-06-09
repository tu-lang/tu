// Intrusive doubly linked list
// Related: packages-asyncio-runtime task 2.1 / 2.2, R1.5
// Design: design §25.1
//
// This is the shared foundation for every intrusive list inside asyncio:
// task.OwnedTasks, ScheduledIo.waiters, time wheel slots, sync.Notify /
// Semaphore.waiters all embed Pointers as their first field and use LinkedList
// for O(1) push_back / pop_front / remove.
//
// TuLang has no generic class, so this implementation models nodes as Pointers*:
//   - The host mem must place Pointers at offset 0 so (NodeMem*) and (Pointers*)
//     are interchangeable at zero cost.
//   - Only the Pointers chain is maintained internally; recovering the outer node
//     from a Pointers* is the caller's responsibility (a plain pointer cast).
//
// `api Link` is kept here as the contract surface in case dynamic dispatch is
// needed later (per design §25.1). Phase-1 callers may simply cast directly and
// skip the api invocation.

// Pointer pair embedded by every list-resident node
mem Pointers {
    Pointers* prev
    Pointers* next
}

// Linked-list node contract (design §25.1)
//   Implementations must return a pointer to their embedded Pointers; when
//   Pointers sits at offset 0 a direct cast is sufficient.
api Link {
    fn pointers() (Pointers)
}

// List head: only the head and tail node pointers
class LinkedList {
    head    // Pointers*
    tail    // Pointers*
}

LinkedList::init(){
    this.head = null
    this.tail = null
}

// is_empty(): the list is empty when head == null
LinkedList::is_empty() bool {
    if this.head == null return true
    return false
}

// push_front(node): insert node at the head.
//   The node must not currently belong to any list (prev/next == null).
LinkedList::push_front(node<Pointers*>){
    node.prev = null
    node.next = this.head
    if this.head != null {
        this.head.prev = node
    } else {
        // empty list: tail also points at the new node
        this.tail = node
    }
    this.head = node
}

// push_back(node): insert node at the tail.
//   The node must not currently belong to any list (prev/next == null).
LinkedList::push_back(node<Pointers*>){
    node.prev = this.tail
    node.next = null
    if this.tail != null {
        this.tail.next = node
    } else {
        this.head = node
    }
    this.tail = node
}

// pop_front(): detach and return the head node; null when the list is empty
LinkedList::pop_front() Pointers* {
    n<Pointers*> = this.head
    if n == null return null
    this.head = n.next
    if this.head != null {
        this.head.prev = null
    } else {
        this.tail = null
    }
    n.prev = null
    n.next = null
    return n
}

// pop_back(): detach and return the tail node; null when the list is empty
LinkedList::pop_back() Pointers* {
    n<Pointers*> = this.tail
    if n == null return null
    this.tail = n.prev
    if this.tail != null {
        this.tail.next = null
    } else {
        this.head = null
    }
    n.prev = null
    n.next = null
    return n
}

// remove(node): O(1) detach `node` from the list.
//   Caller must guarantee the node is currently on `this`; after the call
//   node.prev and node.next are reset to null.
LinkedList::remove(node<Pointers*>){
    if node.prev != null {
        node.prev.next = node.next
    } else {
        this.head = node.next
    }
    if node.next != null {
        node.next.prev = node.prev
    } else {
        this.tail = node.prev
    }
    node.prev = null
    node.next = null
}
