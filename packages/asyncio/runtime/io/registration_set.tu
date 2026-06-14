// Owns every ScheduledIo allocated by the IO driver. Linked via
// ScheduledIo.linked_list_pointers so shutdown can drain them all.

use runtime
use netio

// Mutex-protected list head/tail and live count.
mem RegistrationSetSynced {
    ScheduledIo* head      // null when empty
    ScheduledIo* tail      // null when empty
    u32          num
}

// Public handle bundling the lock and the synced fields.
mem RegistrationSet {
    runtime.MutexInter   lock
    RegistrationSetSynced* synced
}

// Build an empty set.
const RegistrationSet::new() RegistrationSet* {
    s<RegistrationSetSynced> = new RegistrationSetSynced
    s.head = null
    s.tail = null
    s.num  = 0
    rs<RegistrationSet> = new RegistrationSet
    rs.lock.init()
    rs.synced = &s
    return &rs
}

// Allocate a ScheduledIo and link it at the tail. Returns the shared shadow
// the IO driver hands back to Registration.
RegistrationSet::allocate(interest<netio.Interest>) (i32, ScheduledIo*) {
    sio<ScheduledIo*> = ScheduledIo::new()
    this.lock.lock()
    s<RegistrationSetSynced> = this.synced
    if s.tail != null {
        prev<ScheduledIo> = s.tail
        prev.linked_list_pointers.next = &sio.linked_list_pointers
        sio.linked_list_pointers.prev  = &prev.linked_list_pointers
    } else {
        s.head = sio
    }
    s.tail = sio
    s.num += 1
    this.lock.unlock()
    return 0, sio
}

// Detach sio from the global list. Caller must guarantee sio is on this set.
RegistrationSet::release(sio<ScheduledIo>){
    this.lock.lock()
    s<RegistrationSetSynced> = this.synced
    p<Pointers> = sio.linked_list_pointers
    if p.prev != null {
        prev_node<Pointers*> = p.prev
        prev_node.next = p.next
    } else {
        if p.next == null {
            s.head = null
        } else {
            nxt<Pointers> = p.next
            s.head = nxt.(ScheduledIo)
        }
    }
    if p.next != null {
        next_node<Pointers*> = p.next
        next_node.prev = p.prev
    } else {
        if p.prev == null {
            s.tail = null
        } else {
            prv<Pointers> = p.prev
            s.tail = prv.(ScheduledIo)
        }
    }
    sio.linked_list_pointers.prev = null
    sio.linked_list_pointers.next = null
    s.num -= 1
    this.lock.unlock()
}

// Walk the entire list and invoke ScheduledIo::shutdown on each shadow.
// Used by IoDriver::shutdown so every waiter wakes with OtherDriverTerminated.
RegistrationSet::drain_all_for_shutdown(){
    this.lock.lock()
    s<RegistrationSetSynced> = this.synced
    cur<ScheduledIo> = s.head
    this.lock.unlock()
    // Drop the lock before calling shutdown; shutdown grabs ScheduledIo's
    // own waiters_lock, and reactor wake-ups must run unsynchronised.
    while cur != null {
        nxt_node<Pointers> = cur.linked_list_pointers.next
        cur.shutdown()
        if nxt_node == null break
        cur = nxt_node.(ScheduledIo)
    }
}

// Live count snapshot under the lock.
RegistrationSet::num() u32 {
    this.lock.lock()
    s<RegistrationSetSynced> = this.synced
    n<u32> = s.num
    this.lock.unlock()
    return n
}

