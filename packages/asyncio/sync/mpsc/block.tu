// 32-slot ring segment used by mpsc.list. Producers race for slots via
// CAS on ready_slots; consumers walk slots in index order and take the
// next ready bit.

use std.atomic

BLOCK_CAP<u32> = 32

// One block in the linked-list backing the channel.
mem Block {
    u32     start_index    // index of slots[0] in the global stream
    Block*  next           // null until producer chases the tail past this block
    u64     ready_slots    // atomic bitmask; bit i set when slots[i] holds a value
    i64     slots[32]      // payload bits; readers cast via slot.(SomeMem)
}

// Build an empty block whose first slot represents global index `start`.
const Block::new(start<u32>) Block {
    b<Block> = new Block
    b.start_index = start
    b.next        = null
    b.ready_slots = 0
    return b
}

// True when bit `idx` is set in ready_slots.
fn block_slot_ready(bits<u64>, idx<u32>) bool {
    if (bits & (1.(u64) << idx.(u64))) != 0 return true
    return false
}

// Mark slot idx as containing `value`. Returns 0 on success or io.Other
// if the bit was already set (caller must retry on the next block).
Block::try_push(idx<u32>, value<i64>) i32 {
    addr<u64*> = &this.ready_slots
    loop {
        cur<u64> = atomic.load64(addr)
        bit<u64> = 1.(u64) << idx.(u64)
        if (cur & bit) != 0 return io.Other
        new_bits<u64> = cur | bit
        if atomic.cas64(addr.(i64*), cur.(i64), new_bits.(i64)) != 0 {
            this.slots[idx] = value
            return 0
        }
    }
    return io.Other
}

// Take slot idx if ready; returns (NotFound, 0) when not yet published.
Block::try_pop(idx<u32>) (i32, i64) {
    cur<u64> = atomic.load64(&this.ready_slots)
    if block_slot_ready(cur, idx) == false return io.NotFound, 0
    return 0, this.slots[idx]
}

