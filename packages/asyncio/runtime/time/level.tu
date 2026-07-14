// One level of the hashed timer wheel. 64 slots per level; occupied is a
// 64-bit bitfield over them. Each slot stores a doubly linked list of
// TimerShared via the embedded Pointers.

use std
use asyncio.util

LEVEL_SLOTS<i32> = 64
LEVEL_MASK<u64>  = 63

// Singly linked timer list with explicit head + tail.
mem EntryList {
    TimerShared* head      // null when empty
    TimerShared* tail      // null when empty
}

// Build an empty list.
const EntryList::new() EntryList {
    l<EntryList> = new EntryList
    l.head = null
    l.tail = null
    return l
}

// True when no entries are linked.
EntryList::is_empty() i32 {
    if this.head == null return 1
    return 0
}

// Append entry at tail; entry's pointers must be detached.
EntryList::push_back(entry<TimerShared>){
    entry.pointers.prev = null
    entry.pointers.next = null
    if this.tail != null {
        prev<TimerShared> = this.tail
        prev.pointers.next = &entry.pointers
        entry.pointers.prev = &prev.pointers
    } else {
        this.head = entry
    }
    this.tail = entry
}

// Detach the head and return it; null when empty.
EntryList::pop_front() TimerShared {
    e<TimerShared> = this.head
    if e == null return null
    nxt_node<util.Pointers> = e.pointers.next
    if nxt_node == null {
        this.head = null
        this.tail = null
    } else {
        nxt<TimerShared> = nxt_node.(TimerShared)
        nxt.pointers.prev = null
        this.head = nxt
    }
    e.pointers.prev = null
    e.pointers.next = null
    return e
}

// One level of the hashed wheel. occupied bit i toggles when slots[i]
// transitions empty<->non-empty.
mem Level {
    u32   level
    u64   occupied
    u64*  slots         // raw bits of EntryList*; length LEVEL_SLOTS
}

// Resolve EntryList* bits stored in Level.slots[slot].
fn slot_list(slots<u64*>, slot<i32>) EntryList {
    bits<u64> = slots[slot]
    return bits.(EntryList)
}

// Build an empty Level.
const Level::new(level<u32>) Level {
    lv<Level> = new Level
    lv.level    = level
    lv.occupied = 0
    arr<u64*> = std.malloc(sizeof(u64) * LEVEL_SLOTS.(u64))
    for i<i32> = 0 ; i < LEVEL_SLOTS ; i += 1 {
        el<EntryList> = EntryList::new()
        arr[i] = el.(u64)
    }
    lv.slots = arr
    return lv
}

// Append entry to the slot. occupied bit is set on the empty -> non-empty edge.
Level::add_entry(slot<i32>, entry<TimerShared>){
    s<EntryList> = slot_list(this.slots, slot)
    was_empty<i32> = s.is_empty()
    s.push_back(entry)
    if was_empty != 0 {
        this.occupied = this.occupied | (1.(u64) << slot.(u64))
    }
}

// Detach entry from slot. Caller must guarantee entry currently lives there.
Level::remove_entry(slot<i32>, entry<TimerShared>){
    s<EntryList> = slot_list(this.slots, slot)
    p<util.Pointers> = entry.pointers
    if p.prev != null {
        prev_node<util.Pointers> = p.prev
        prev_node.next = p.next
    } else {
        if p.next == null {
            s.head = null
        } else {
            nxt_ptr<util.Pointers> = p.next
            nxt<TimerShared> = nxt_ptr.(TimerShared)
            nxt.pointers.prev = null
            s.head = nxt
        }
    }
    if p.next != null {
        next_node<util.Pointers> = p.next
        next_node.prev = p.prev
    } else {
        if p.prev == null {
            s.tail = null
        } else {
            prv_ptr<util.Pointers> = p.prev
            prv<TimerShared> = prv_ptr.(TimerShared)
            prv.pointers.next = null
            s.tail = prv
        }
    }
    entry.pointers.prev = null
    entry.pointers.next = null
    if s.is_empty() != 0 {
        this.occupied = this.occupied & (~(1.(u64) << slot.(u64)))
    }
}

// Take ownership of an entire slot's list, leaving the slot empty.
Level::take_slot(slot<i32>) EntryList {
    src<EntryList> = slot_list(this.slots, slot)
    out<EntryList> = EntryList::new()
    out.head = src.head
    out.tail = src.tail
    src.head = null
    src.tail = null
    this.occupied = this.occupied & (~(1.(u64) << slot.(u64)))
    return out
}

// Trailing-zero scan over occupied; returns -1 when no slot is set.
Level::next_occupied_slot(start<i32>) i32 {
    bits<u64> = this.occupied
    if bits == 0 return -1
    v<u64> = bits
    if start > 0 {
        // Mask off slots < start, then ctz.
        shift_base<u64> = 1.(u64) << start.(u64)
        mask_lo<u64> = shift_base - 1
        v = bits & (~mask_lo)
        if v == 0 return -1
    }
    n<i32> = 0
    loop {
        low<u64> = v & 1
        if low != 0 break
        v = v >> 1
        n += 1
    }
    return n
}
