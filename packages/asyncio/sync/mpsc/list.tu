// Lock-free producer queue + single-consumer reader over a chain of
// 32-slot Blocks. read_cursor is consumer-private. New blocks are linked
// in lazily by the producer that observes the boundary first.

use std.atomic

// Producer-side handle. tail_index is a global slot counter shared by
// every Sender clone. head_seg is consumer-only; producers walk via next.
mem ListTx {
    Block* head_seg
    u32    tail_index      // atomic; next free global slot
}

// Consumer-side handle. Owned by the single Receiver.
mem ListRx {
    Block* head_seg
    u32    read_cursor     // consumer cursor in global slot space
}

// Build (tx, rx) pair sharing one Block to start with.
fn mpsc_list_new() (ListTx, ListRx) {
    head<Block> = Block::new(0)
    prod<ListTx> = new ListTx { head_seg: head, tail_index: 0 }
    cons<ListRx> = new ListRx { head_seg: head, read_cursor: 0 }
    return prod, cons
}

// Producer push. Atomically claims the next slot, then writes the value.
ListTx::publish(v<i64>) i32 {
    tail_pos<u32> = atomic.xadd(&this.tail_index, 1)
    seg_off<u32> = tail_pos & 31
    walker<Block> = this.head_seg
    loop {
        if tail_pos >= walker.origin_at && tail_pos < (walker.origin_at + BLOCK_CAP) {
            return walker.put_slot(seg_off, v)
        }
        if walker.next == null {
            nxt<Block> = Block::new(walker.origin_at + BLOCK_CAP)
            walker.next = nxt
        }
        walker = walker.next
    }
    return MpscPushBusy
}

// Consumer pop. Walks blocks in global order.
ListRx::pop() (i32, i64) {
    walker<Block> = this.head_seg
    loop {
        if this.read_cursor >= walker.origin_at && this.read_cursor < (walker.origin_at + BLOCK_CAP) {
            seg_off<u32> = this.read_cursor - walker.origin_at
            pop_err<i32>, pop_val<i64> = walker.take_slot(seg_off)
            if pop_err != 0 return pop_err, 0
            this.read_cursor += 1
            if (this.read_cursor - walker.origin_at) >= BLOCK_CAP {
                if walker.next != null this.head_seg = walker.next
            }
            return 0, pop_val
        }
        if walker.next == null return MpscPopEmpty, 0
        walker = walker.next
    }
    return MpscPopEmpty, 0
}
