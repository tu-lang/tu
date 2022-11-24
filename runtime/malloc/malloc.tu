use std
use runtime.sys
use os

physPageSize<u64> = 0

//only for master thread
m0<sys.Core:>
g0<sys.Coroutine:>

func mallocinit()
{
	sys.ncpu = 4
	sys.physPageSize = 4096
	sys.gcphase = _GCoff
	sys.gcBlackenEnabled = false

	heap_.init()

	g_ = &g0
    g_.m = &m0
    g_.m.mallocing  = 0
    g_.m.mcache = allocmcache()
	m0.mid = 0
	m0.pid = 10
	//TODO:
	// heap_.allspans.init(ARRAY_SIZE,sizeof(Span))
	heap_.locks.init()
	c0<u64> = 0xc0
    for i<i32> = 0x7f; i >= 0; i -= 1 {
		p<u64> = 0
		p = i<<40 | (u64Mask & (c0<<32) )
		hint<ArenaHint> = heap_.arenaHintAlloc.alloc()
		hint.addr = p
		hint.next = heap_.arenaHints
		heap_.arenaHints = hint
	}

	sys.allm[0] = g_.m
	while(sys.gcphase != _GCoff){}

}

func largeAlloc(size<u64>, needzero<u8> , noscan<u8>)
{
	if size + sys.pageSize < size {
		dief("out of memory\n".(i8))
	}
	npages<u64> = 0
	s<Span> = null

	npages = size >> pageShift 
	if( size & PageMask != 0 ) {
		npages += 1
	}
	s = heap_.alloc(npages, makeSpanClass(0.(i8),noscan), 1.(i8), needzero)
	if( s == null ){
		dief("out of memory\n".(i8))
	}
	s.limit = s.startaddr + size
	h<HeapBits:> = null
	h.heapBitsForAddr(s.startaddr)
	h.initSpan(s)
	return s
}
