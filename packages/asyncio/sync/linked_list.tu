// Intrusive doubly linked list for asyncio.sync waiter queues.
// Nodes must place Pointers at offset 0 so a Pointers reference and a
// node mem reference are interchangeable; the list only walks the chain.

// Pointer pair embedded by every list-resident node.
mem Pointers {
    Pointers* prev
    Pointers* next
}

// Returns the embedded Pointers; default impl when Pointers sits at offset 0.
api Link {
    fn pointers() (Pointers)
}

// Head + tail of an intrusive list. Both null when empty.
mem LinkedList {
    Pointers* head
    Pointers* tail
}

// Build an empty list.
const LinkedList::new() LinkedList {
    l<LinkedList> = new LinkedList
    l.head = null
    l.tail = null
    return l
}

// True when no nodes are linked.
LinkedList::is_empty() i32 {
    if this.head == null return 1
    return 0
}

// Return the head node without removing it; null when empty.
LinkedList::peek_head() Pointers {
    return this.head
}

// Prepend node. Caller must guarantee node currently belongs to no list.
LinkedList::push_front(node<Pointers>){
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
LinkedList::push_back(node<Pointers>){
    node.prev = this.tail
    node.next = null
    if this.tail != null {
        this.tail.next = node
    } else {
        this.head = node
    }
    this.tail = node
}

// Detach + return the head node. Returns null when empty.
LinkedList::pop_front() Pointers {
    n<Pointers> = this.head
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
LinkedList::pop_back() Pointers {
    n<Pointers> = this.tail
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
LinkedList::remove(node<Pointers>){
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
