use std
use os
use runtime.sys

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


fn arenaIndex(p<u64>) {
    return (p + arenaBaseOffset) / heapArenaBytes
}
fn arena_l1(i<u32>){
    if arenaL1Bits == 0 return 0.(i8)
    return i >> arenaL1Shift
}
fn arena_l2(i<u32>){
    if arenaL1Bits == 0 return i
    return i & (1 << arenaL2Bits - 1)
}

fn pageIndexOf(p<u64> , pageIdx<u64*> , pageMask<u8*>)
{
    ai<u32> = arenaIndex(p)
    arr<u64*> = heap_.arenas[arena_l1(ai)]

    arena<u64*> = arr[arena_l2(ai)]
    *pageIdx = ((p / sys.pageSize) / 8) % (pagesPerArena / 8 )
    *pageMask = 1 << ((p / sys.pageSize) % 8)
    return arena
}

mem GcBitsArena {
    u64 		 free
    GcBitsArena* next
    u8 			 bits[65520]
}

mem GcBitsArenas {
    sys.MutexInter    locks 
    GcBitsArena* free
    GcBitsArena* next
    GcBitsArena* current
    GcBitsArena* previous
}

gbArenas<GcBitsArenas:> = null

GcBitsArena::tryAlloc(u8s<u64>) 
{
	bitslen<u64> = gcBitsChunkBytes - gcBitsHeaderBytes
	if this == null || atomic.load64(&this.free) + u8s > bitslen {
		return 0.(i8)
	}
	end<u64> = atomic.xadd64(&this.free, u8s)
	if end > bitslen {
		return 0.(i8)
	}
	start<u64> = end - u8s
	return &this.bits[start]
}

GcBitsArenas::newArenaMayUnlock()
{
	result<GcBitsArena> = null
	if this.free == null {
		this.locks.unlock()
		result = sys.alloc(gcBitsChunkBytes)
		if result == null  {
			dief("runtime: cannot allocate memory".(i8))
		}
		this.locks.lock()
	} else {
		result = this.free
		this.free = this.free.next
		std.memset(result,0.(i8),gcBitsChunkBytes)
	}
	result.next = null
	result.free = 0
	return result
}

mem HeapBits {
    u8* bitp
    u32 shift
    u32 arena
    u8* last
}

HeapBits::initSpan(s<Span>)
{
	size<u64>  = 0
	n<u64> 	   = 0
	total<u64> = 0
	s.layout(&size,&n,&total)

	s.freeindex = 0
	s.allocCache = -1 # ~0 = 18446744073709551615
	s.nelems = n
	s.allocBits = null
	s.gcmarkBits = null
	s.gcmarkBits = newMarkBits(s.nelems)
	s.allocBits = newMarkBits(s.nelems)

	nw<u64> = total / ptrSize
	if nw % wordsPerBitmapByte != 0 {
		dief("initSpan: unaligned length".(i8))
	}
	if this.shift != 0 {
		dief("initSpan: unaligned base".(i8))
	}
	while nw > 0 {
		anw<u64> = 0
		obitp<u8*> = this.bitp
		this.forwardOrBoundary(nw,&anw)
		nu8<u64>  = anw / wordsPerBitmapByte
		if ptrSize == 8 && size == ptrSize {
			bitp<u8*> = obitp
			for i<u64> = 0; i < nu8; i += 1 {
				*bitp = bitPointerAll | bitScanAll
				bitp += 1
			}
		} else {
			std.memset(obitp,0.(i8),nu8)
		}
		nw -= anw
	}
}
HeapBits::forwardOrBoundary(n<u64> , nw<u64*>)
{
	maxn<u64> = 4 * (this.last + 1 - this.bitp)
	if n > maxn {
		n = maxn
	}
	*nw = n
	this.forward(n)
}
HeapBits::forward(n<u64>)
{
	n += this.shift / heapBitsShift
	nbitp<u64> = this.bitp + n / 4
	this.shift = (n % 4) * heapBitsShift
	if nbitp <= this.last {
		this.bitp = nbitp
		return 0.(i8)
	}

	past<u64> = nbitp - (this.last + 1)
	this.arena += 1 + (past / heapArenaBitmapBytes)
	ai<u32> = this.arena
	ae<u64*> = heap_.arenas[arena_l1(ai)]
	if	ae != null && ae[arena_l2(ai)] != null {
		p<HeapArena> = ae[arena_l2(ai)]
        this.bitp = &p.bitmap[past % heapArenaBitmapBytes]
		this.last = &p.bitmap[heapArenaBitmapBytes - 1]
	} else {
	    this.bitp = null
	    this.last = null
	}
	return 0.(i8)
}
HeapBits::heapBitsForAddr(addr<u64>){
	arena<u32> = arenaIndex(addr)
	arr<u64*> = heap_.arenas[arena_l1(arena)]
	ha<HeapArena>   = arr[arena_l2(arena)]
	if  ha == null {
		return 0.(i8)
	}
	this.bitp = &ha.bitmap[(addr/(ptrSize*4))%heapArenaBitmapBytes]
	this.shift = (addr / ptrSize) & 3
	this.arena = arena
	this.last = &ha.bitmap[heapArenaBitmapBytes - 1]
	return this
}


 fn newMarkBits(nelems<u64>)
 {
	blocksNeeded<u64> = (nelems + 63) / 64
	u8sNeeded<u64> = blocksNeeded * 8
	head<GcBitsArena> = atomic.load64(&gbArenas.next)
	p<u8*> = head.tryAlloc(u8sNeeded)
 	if  p != null {
 		return p
 	}

 	gbArenas.locks.lock()
	p = gbArenas.next.tryAlloc(u8sNeeded)
 	if p != null {
		gbArenas.locks.unlock()
 		return p
 	}

	fresh<GcBitsArena> = gbArenas.newArenaMayUnlock()

	p = gbArenas.next.tryAlloc(u8sNeeded)
 	if  p != null {
 		fresh.next = gbArenas.free
 		gbArenas.free = fresh
		gbArenas.locks.unlock()
 		return p
 	}

	p = fresh.tryAlloc(u8sNeeded)
 	if  p == null {
 		dief("markBits overflow".(i8))
 	}

 	fresh.next = gbArenas.next
	atomic.store64(&gbArenas.next,fresh)

	gbArenas.locks.unlock()
 	return p
}
fn nextMarkBitArenaEpoch()
{
	gbArenas.locks.lock()
	if gbArenas.previous != null  {
		if  gbArenas.free == null  {
			gbArenas.free = gbArenas.previous
		} else {
			last<GcBitsArena> = gbArenas.previous
			for last = gbArenas.previous ; last.next != null ; last = last.next {}
			last.next = gbArenas.free
			gbArenas.free = gbArenas.previous
		}
	}
	gbArenas.previous = gbArenas.current
	gbArenas.current = gbArenas.next
	atomic.store64(&gbArenas.next,0.(i8))
	gbArenas.locks.unlock()
}
