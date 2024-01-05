use std
use std.atomic
use runtime.sys
use os

oneBitCount<u8:256> = [
	0, 1, 1, 2, 1, 2, 2, 3,
	1, 2, 2, 3, 2, 3, 3, 4,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	4, 5, 5, 6, 5, 6, 6, 7,
	5, 6, 6, 7, 6, 7, 7, 8
]

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


 func newMarkBits(nelems<u64>)
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
func nextMarkBitArenaEpoch()
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
