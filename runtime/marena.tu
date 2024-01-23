use std
use os

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
    *pageIdx = ((p / pageSize) / 8) % (pagesPerArena / 8 )
    *pageMask = 1 << ((p / pageSize) % 8)
    return arena
}

mem GcBitsArena {
    u64 		 free
    GcBitsArena* next
    u8 			 bits[65520]
}

mem GcBitsArenas {
    MutexInter   lock
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
		this.lock.unlock()
		result = sys_alloc(gcBitsChunkBytes)
		if result == null  {
			dief("runtime: cannot allocate memory".(i8))
		}
		this.lock.lock()
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
HeapBits::empty(){
	this.bitp = Null
	this.shift = 0
	this.arena = 0
	this.last = Null
	return this
}
HeapBits::nextArena(){
	this.arena += 1
    ai<u32> = arenaIndex(this.arena)
	arr<u64*> = heap_.arenas[arena_l1(ai)]
	ha<HeapArena> = arr[arena_l2(ai)]
	if ha == Null {
		return this.empty()
	}
	this.bitp = &ha.bitmap[0]
	this.shift = 0
	this.last = &ha.bitmap[heapArenaBitmapBytes - 1]
	return this
}
HeapBits::bits(){
	bitp<u32> = *this.bitp
	return bitp >> (this.shift & 31)
}
HeapBits::next(){
	if this.shift < 3 * heapBitsShift {
		this.shift += heapBitsShift
	}else if(this.bitp != this.last){
		this.bitp +=  1
	}else {
		return this.nextArena()
	}
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

 	gbArenas.lock.lock()
	p = gbArenas.next.tryAlloc(u8sNeeded)
 	if p != null {
		gbArenas.lock.unlock()
 		return p
 	}

	fresh<GcBitsArena> = gbArenas.newArenaMayUnlock()

	p = gbArenas.next.tryAlloc(u8sNeeded)
 	if  p != null {
 		fresh.next = gbArenas.free
 		gbArenas.free = fresh
		gbArenas.lock.unlock()
 		return p
 	}

	p = fresh.tryAlloc(u8sNeeded)
 	if  p == null {
 		dief("markBits overflow".(i8))
 	}

 	fresh.next = gbArenas.next
	atomic.store64(&gbArenas.next,fresh)

	gbArenas.lock.unlock()
 	return p
}
fn nextMarkBitArenaEpoch()
{
	gbArenas.lock.lock()
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
	gbArenas.lock.unlock()
}

mem Cache {
    u64    local_scan , tiny , tinyoffset , local_tinyallocs
    Span*     alloc[numSpanClasses]
    u64       local_nsmallfree[_NumSizeClasses]
    u32       flushGen
}

Cache::nextFree(spc<u8>,ss<u64*>,shouldgc<u8*>)
{
	s<Span> = this.alloc[spc]
	*shouldgc = false
	freeIndex<u64> = s.nextFreeIndex()

	if freeIndex == s.nelems {
		if s.allocCount != s.nelems {
			dief("s.allocCount != s.nelems && freeIndex == s.nelems".(i8))
		}
		this.refill(spc)
		*shouldgc = true
		s = this.alloc[spc]

		freeIndex = s.nextFreeIndex()
	}

	if freeIndex >= s.nelems {
		dief("freeIndex is not valid".(i8))
	}
	v<u64> = freeIndex* s.elemsize + s.startaddr
	s.allocCount += 1
	if s.allocCount > s.nelems {
		dief("s.allocCount > s.nelems".(i8))
	}
	return v
}
Cache::refill(spc<u8>)
{
	s<Span> = this.alloc[spc]

	if s.allocCount != s.nelems {
		dief("refill of span with free space remaining\n".(i8))
	}
	if s != &emptyspan {
		if s.sweepgen != heap_.sweepgen + 3 {
			dief("bad sweepgen in refill\n".(i8))
		}
		atomic.store32(&s.sweepgen,heap_.sweepgen)
	}

	s = heap_.centrals[spc].cacheSpan()
	if s == null {
		dief("out of memory".(i8))
	}

	if s.allocCount == s.nelems {
		dief("span has no free space".(i8))
	}

	s.sweepgen = heap_.sweepgen +  3

	this.alloc[spc] =  s
}
fn allocmcache(){
	heap_.lock.lock()
	c<Cache> = heap_.cachealloc.alloc()
	c.flushGen = heap_.sweepgen
	heap_.lock.unlock()
	for i<i32> = 0 ; i < numSpanClasses ; i += 1{
		c.alloc[i] = &emptyspan
	}
	return c
}

Cache::releaseAll()
{
	for i<i32> = 0 ; i < numSpanClasses ; i += 1 {
		s<Span> = this.alloc[i]
		if s != &emptyspan {
			heap_.centrals[i].uncacheSpan(s)
			this.alloc[i] = &emptyspan
		}
	}
	atomic.store32(&this.flushGen,heap_.sweepgen)

	this.tiny = 0
	this.tinyoffset = 0
}

mem Central {
    MutexInter  lock
    u8     sc

    Spanlist  nonempty
    Spanlist  empty
    u64    	  nmalloc
}


Central::init(i<u8>)
{
	this.sc = i
	this.empty.first = null
	this.empty.last  = null

	this.nonempty.first = null
	this.nonempty.last  = null

}

Central::cacheSpan()
{
	spanBytes<u64> = class_to_allocnpages[sizeclass(this.sc)] * pageSize

	this.lock.lock()
	traceDone<u8> = false
	sg<u32> = heap_.sweepgen
	
cachespanretry:
	s<Span> = null
	for ( s = this.nonempty.first; s != null; s = s.next ) {

		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen,sg - 2,sg - 1) == True {
			this.nonempty.remove(s)
			this.empty.insertback(s)
			this.lock.unlock()
			goto havespan
		}
		if s.sweepgen == sg - 1 {
			continue
		}
		this.nonempty.remove(s)
		this.empty.insertback(s)
		this.lock.unlock()
		goto havespan
	}

	for s = this.empty.first; s != null; s = s.next {
		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen, sg - 2, sg - 1) == True {
			this.empty.remove(s)
			this.empty.insertback(s)
			this.lock.unlock()
			freeIndex<u64> = s.nextFreeIndex()
			if freeIndex != s.nelems {
				s.freeindex = freeIndex
				goto havespan
			}
			this.lock.lock()
			goto cachespanretry
		}
		if s.sweepgen == sg - 1 { 
			continue
		}
		break
	}
	this.lock.unlock()

	s = this.grow()
	if s == null {
		return 0.(i8)
	}
	this.lock.lock()
	this.empty.insertback(s)
	this.lock.unlock()

havespan:

	n<i32> = s.nelems - s.allocCount
	if n == 0 || s.freeindex == s.nelems || s.allocCount == s.nelems {
		dief("span has no free objects".(i8))
	}
	atomic.xadd64(&this.nmalloc, n)
	usedBytes<u64> = s.allocCount * s.elemsize
	if gcBlackenEnabled != 0 {
		// heap_live changed.
		//		gcController.revise()
	}
	_t<i64> = 63
	freeByteBase<u64> = s.freeindex &~ _t
	whichByte<u64>    = freeByteBase / 8
	s.refillAllocCache(whichByte)

	s.allocCache >>= s.freeindex % 64

	return s
}


Central::grow()
{
	npages<u64> = class_to_allocnpages[sizeclass(this.sc)]
	size<u64>   = class_to_size[sizeclass(this.sc)]
	n<u64> 	   = (npages << pageShift) / size

	s<Span> = heap_.alloc(npages, this.sc, 0.(i8), 1.(i8))
	if s == null {
		return 0.(i8)
	}

	p<u64> = s.startaddr
	s.limit = p + size * n
	h<HeapBits:> = null
	h.heapBitsForAddr(s.startaddr)
	h.initSpan(s)
	return s
}

Central::freeSpan(s<Span> , preserve<u8> , wasempty<u8>)
{
	sg<u32> = heap_.sweepgen

	if  s.sweepgen == sg + 1 || s.sweepgen == sg + 3 {
		dief("freeSpan given cached span".(i8))
	}
	s.needzero = 1

	if preserve {
		if s.list == null {
			dief("can't preserve unlinked span".(i8))
		}
		atomic.store(&s.sweepgen,heap_.sweepgen)
		return 0.(i8)
	}

	this.lock.lock()

	if wasempty {
		this.empty.remove(s)
		this.nonempty.insert(s)
	}

	atomic.store(&s.sweepgen,heap_.sweepgen)

	if s.allocCount != 0 {
		this.lock.unlock()
		return 0.(i8)
	}
	this.nonempty.remove(s)
	this.lock.unlock()
	heap_.freeSpan(s,0.(i8))
	return 1.(i8)
}

Central::uncacheSpan(s<Span>)
{
	if s.allocCount == 0 {
		dief("uncaching span but s.allocCount == 0".(i8))
	}

	sg<u32>  = heap_.sweepgen
	stale<u8> = s.sweepgen == sg+1
	if stale {
		atomic.store(&s.sweepgen, sg - 1)
	} else {
		atomic.store(&s.sweepgen, sg)
	}

	n<i32> = s.nelems - s.allocCount
	if  n > 0 {
		this.lock.lock()
		this.empty.remove(s)
		this.nonempty.insert(s)
		if  !stale {
		}
		this.lock.unlock()
	}

	if stale {
	}
}