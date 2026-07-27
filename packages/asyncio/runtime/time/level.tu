// One level of the hashed timer wheel. 64 slots per level; occupied is a
// 64-bit bitfield over them. Each slot stores a doubly linked list of
// TimerShared via the embedded Pointers.

use std
use asyncio.util

LEVEL_SLOTS<i32> = 64
LEVEL_MASK<u64>  = 63
LEVEL_MULT_U<u64> = 64

// Intrusive timer list. TimerShared* stored as u64 — avoid `.head` / `.front`
// field names (type-assert traps). Use is_empty() / front_entry() at boundaries.
mem EntryList {
    u64 front_bits     // TimerShared* or 0
    u64 back_bits      // TimerShared* or 0
}

// Build an empty list.
const EntryList::new() EntryList {
    l<EntryList> = new EntryList
    l.front_bits = 0
    l.back_bits = 0
    return l
}

// True when no entries are linked.
EntryList::is_empty() i32 {
    bits<u64> = this.front_bits
    if bits == 0 return 1
    return 0
}

EntryList::front_entry() TimerShared {
    bits<u64> = this.front_bits
    if bits == 0 return null
    return bits.(TimerShared)
}

EntryList::set_front(entry<TimerShared>){
    if entry == null {
        this.front_bits = 0
        return
    }
    b<u64> = 0
    b = entry
    this.front_bits = b
}

EntryList::set_back(entry<TimerShared>){
    if entry == null {
        this.back_bits = 0
        return
    }
    b<u64> = 0
    b = entry
    this.back_bits = b
}

// Append entry at tail; entry's pointers must be detached.
EntryList::push_back(entry<TimerShared>){
    entry.pointers.prev = null
    entry.pointers.next = null
    ebits<u64> = 0
    ebits = entry
    ep<util.Pointers> = ebits.(util.Pointers)
    back<u64> = this.back_bits
    if back != 0 {
        tp<util.Pointers> = back.(util.Pointers)
        tp.next = ep
        ep.prev = tp
    } else {
        this.set_front(entry)
    }
    this.set_back(entry)
}

// Detach the head and return it; null when empty.
EntryList::pop_front() TimerShared {
    e<TimerShared> = this.front_entry()
    if e == null return null
    nxt_p<util.Pointers> = e.pointers.next
    if nxt_p == null {
        this.front_bits = 0
        this.back_bits = 0
    } else {
        nbits<u64> = 0
        nbits = nxt_p
        nxt<TimerShared> = nbits.(TimerShared)
        nxt.pointers.prev = null
        this.set_front(nxt)
    }
    e.pointers.prev = null
    e.pointers.next = null
    return e
}

// One level of the hashed wheel. occupied bit i toggles when slots[i]
// transitions empty<->non-empty.
// Field is `tier` (not `level`) — `.level` is a type-assert trap.
mem Level {
    u32   tier
    u64   occupied
    u64*  slots         // raw bits of EntryList*; length LEVEL_SLOTS
}

// Resolve EntryList* bits stored in Level.slots[slot].
fn slot_list(slots<u64*>, slot<i32>) EntryList {
    bits<u64> = slots[slot]
    return bits.(EntryList)
}

// Build an empty Level.
const Level::new(tier<u32>) Level {
    lv<Level> = new Level
    lv.tier     = tier
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
    ebits<u64> = 0
    ebits = entry
    p<util.Pointers> = ebits.(util.Pointers)
    if p.prev != null {
        prev_node<util.Pointers> = p.prev
        prev_node.next = p.next
    } else {
        if p.next == null {
            s.front_bits = 0
        } else {
            nbits<u64> = 0
            nbits = p.next
            nxt<TimerShared> = nbits.(TimerShared)
            nxt.pointers.prev = null
            s.set_front(nxt)
        }
    }
    if p.next != null {
        next_node<util.Pointers> = p.next
        next_node.prev = p.prev
    } else {
        if p.prev == null {
            s.back_bits = 0
        } else {
            pbits<u64> = 0
            pbits = p.prev
            prv<TimerShared> = pbits.(TimerShared)
            prv.pointers.next = null
            s.set_back(prv)
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
    out.front_bits = src.front_bits
    out.back_bits = src.back_bits
    src.front_bits = 0
    src.back_bits = 0
    this.occupied = this.occupied & (~(1.(u64) << slot.(u64)))
    return out
}

// Trailing-zero scan over occupied; returns -1 when no slot is set.
// start is a slot index (legacy); prefer next_expiration for poll.
Level::next_occupied_slot(start<i32>) i32 {
    bits<u64> = this.occupied
    if bits == 0 return -1
    v<u64> = bits
    if start > 0 {
        shift_base<u64> = 1.(u64) << start.(u64)
        mask_lo<u64> = shift_base - 1
        v = bits & (~mask_lo)
        if v == 0 return -1
    }
    n<i32> = 0
    loop {
        if n >= LEVEL_SLOTS return -1
        low<u64> = v & 1
        if low != 0 break
        v = v >> 1
        n += 1
    }
    return n
}
