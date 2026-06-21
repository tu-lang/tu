// Lock-free producer queue + single-consumer reader over a chain of
// 32-slot Blocks. tail_index is bumped atomically by every push;
// head_index is consumer-private. New blocks are linked in lazily by
// the producer that observes the boundary first.

use std.atomic

// Producer-side handle. tail_index is a global slot counter shared by
// every Sender clone. head_block is consumer-only; producers walk it via
// `next`.
mem ListTx {
    Block* head_block      // first block; producers traverse via next
    u64    tail_index      // atomic; next free global slot
}

// Consumer-side handle. Owned by the single Receiver.
mem ListRx {
    Block* head_block
    u64    head_index      // consumer cursor in global slot space
}

// Build (tx, rx) pair sharing one Block to start with.
const list_new() (ListTx, ListRx) {
    blk<Block> = Block::new(0)
    tx<ListTx> = new ListTx { head_block: &blk, tail_index: 0 }
    rx<ListRx> = new ListRx { head_block: &blk, head_index: 0 }
    return tx, rx
}

// Locate the block holding global index `idx`, allocating new blocks at
// the tail when needed. Caller must guarantee `start` covers `idx`.
fn list_block_for(start<Block>, idx<u32>) Block* {
    cur<Block> = start
    loop {
        if idx >= cur.start_index && idx < cur.start_index + BLOCK_CAP return &cur
        if cur.next == null {
            nxt<Block> = Block::new(cur.start_index + BLOCK_CAP)
            cur.next = &nxt
        }
        cur = cur.next
    }
    return null
}

// Producer push. Atomically claims the next slot, then writes the value.
// Returns 0 on success or io.Other on bit conflict (extremely rare).
ListTx::push(v<i64>) i32 {
    slot_global<u64> = atomic.xadd64(&this.tail_index, 1)
    block_idx<u32>   = (slot_global / BLOCK_CAP.(u64)).(u32)
    in_block<u32>    = (slot_global % BLOCK_CAP.(u64)).(u32)
    blk<Block> = list_block_for(this.head_block, slot_global.(u32))
    if blk == null return io.Other
    return blk.try_push(in_block, v)
}

// Consumer pop. Walks blocks in global order; returns (NotFound, 0) if
// the slot under head_index hasn't been published yet.
ListRx::pop() (i32, i64) {
    blk<Block> = list_block_for(this.head_block, this.head_index.(u32))
    if blk == null return io.NotFound, 0
    in_block<u32> = (this.head_index - blk.start_index.(u64)).(u32)
    err<i32>, val<i64> = blk.try_pop(in_block)
    if err != 0 return err, 0
    this.head_index += 1
    // Recycle: if we consumed the last slot of head_block and a `next`
    // exists, advance the consumer head past it. Producers may still
    // hold pointers into head_block, but they only walk forwards.
    if (this.head_index - blk.start_index.(u64)).(u32) >= BLOCK_CAP {
        if blk.next != null this.head_block = blk.next
    }
    return 0, val
}

