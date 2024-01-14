use std
use std.atomic
use os
use runtime.sys

mem Cache {
    u64    local_scan , tiny , tinyoffset , local_tinyallocs
    Span*     alloc[numSpanClasses]
    u64       local_nsmallfree[_NumSizeClasses]
    u32       flushGen
}

Cache::nextFree(spc<u8>,ss<u64*>,shouldhelpgc<u8*>)
{
	s<Span> = this.alloc[spc]
	*shouldhelpgc = false
	freeIndex<u64> = s.nextFreeIndex()

	if freeIndex == s.nelems {
		if s.allocCount != s.nelems {
			dief("s.allocCount != s.nelems && freeIndex == s.nelems".(i8))
		}
		this.refill(spc)
		*shouldhelpgc = true
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
	heap_.locks.lock()
	c<Cache> = heap_.cachealloc.alloc()
	c.flushGen = heap_.sweepgen
	heap_.locks.unlock()
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