// Intrusive doubly linked list shared by every asyncio waiter list.
// Nodes must place Pointers at offset 0 so (Pointers*) and (NodeMem*) are
// interchangeable; the list itself only walks the Pointers chain.

// Pointer pair embedded by every list-resident node.
mem Pointers {
    Pointers* prev
    Pointers* next
}

// Returns the embedded Pointers; default impl casts when Pointers sits at offset 0.
api Link {
    fn pointers() (Pointers)
}

// Head + tail of an intrusive list. Both null when empty.
class LinkedList {
    head    // Pointers*
    tail    // Pointers*
}

// Reset to empty state.
LinkedList::init(){
    this.head = null
    this.tail = null
}

LinkedList::is_empty() bool {
    if this.head == null return true
    return false
}

// Prepend node. Caller must guarantee node currently belongs to no list.
LinkedList::push_front(node<Pointers*>){
    node.prev = null
    node.next = this.head
    if this.head != null {
        this.head.prev = node
    } else {
        this.tail = node
    }
    this.head = node
}

// Append node. Caller must guarantee node currently belongs to no list.
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

// Detach + return the head node. Returns null when empty; popped node has prev/next reset.
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

// Detach + return the tail node. Returns null when empty.
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

// O(1) detach. Caller must guarantee node currently lives on this list.
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
