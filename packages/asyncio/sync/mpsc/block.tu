// 32-slot ring segment used by mpsc.list. Producers race for slots via
// CAS on published_bits; consumers walk slots in index order.

use std.atomic

BLOCK_CAP<u32> = 32

// One block in the linked-list backing the channel.
mem Block {
    u32     origin_at      // index of slots[0] in the global stream
    Block*  next           // null until producer chases the tail past this block
    u64     published_bits // atomic bitmask; bit i set when slots[i] holds a value
    i64     slots[32]      // payload bits; readers cast via slot.(SomeMem)
}

// Build an empty block whose first slot represents global index `start`.
const Block::new(start<u32>) Block {
    b<Block> = new Block
    b.origin_at       = start
    b.next            = null
    b.published_bits  = 0
    return b
}

// True when bit `off` is set in published_bits.
fn block_slot_ready(bits<u64>, off<u32>) i32 {
    if (bits & (1.(u64) << off.(u64))) != 0 return 1
    return 0
}

// Mark slot off as containing `value`. Returns 0 on success or MpscPushBusy
// if the bit was already set (caller must retry on the next block).
Block::put_slot(off<u32>, value<i64>) i32 {
    loop {
        cur<u64> = atomic.load64(&this.published_bits)
        bit<u64> = 1.(u64) << off.(u64)
        if (cur & bit) != 0 return MpscPushBusy
        new_bits<u64> = cur | bit
        if atomic.cas64(&this.published_bits, cur.(i64), new_bits.(i64)) != 0 {
            this.slots[off] = value
            return 0
        }
    }
    return MpscPushBusy
}

// Take slot off if ready; returns (MpscPopEmpty, 0) when not yet published.
Block::take_slot(off<u32>) (i32, i64) {
    cur<u64> = atomic.load64(&this.published_bits)
    if block_slot_ready(cur, off) == 0 return MpscPopEmpty, 0
    return 0, this.slots[off]
}
