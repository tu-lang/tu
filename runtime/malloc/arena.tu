use std
use os
use sys

mem ArenaHint {
    u64        addr
    u8         down
    ArenaHint* next
}

mem HeapArena {
    u8      bitmap[heapArenaBitmapBytes]
    Span*   spans[pagesPerArena]
    u8      pageInuse[pagesPerArena / 8 ]
    u8      pageMarks[pagesPerArena / 8]
}


func arenaIndex(p<u64>) {
    return (p + arenaBaseOffset) / heapArenaBytes
}
func arena_l1(i<u32>){
    if arenaL1Bits == 0 return 0.(i8)
    return i >> arenaL1Shift
}
func arena_l2(i<u32>){
    if arenaL1Bits == 0 return i
    return i & (1 << arenaL2Bits - 1)
}

func pageIndexOf(p<u64> , pageIdx<u64*> , pageMask<u8*>)
{
    ai<u32> = arenaIndex(p)
    arr<u64*> = heap_.arenas[arena_l1(ai)]

    arena<u64*> = arr[arena_l2(ai)]
    *pageIdx = ((p / sys.pageSize) / 8) % (pagesPerArena / 8 )
    *pageMask = 1 << ((p / sys.pageSize) % 8)
    return arena
}
