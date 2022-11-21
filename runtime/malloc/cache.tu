use std
use std.atomic
use os
use sys

mem Cache {
    u64    local_scan , tiny , tinyoffset , local_tinyallocs
    Span*     alloc[numSpanClasses]
    u64       local_nsmallfree[_NumSizeClasses]
    u32       flushGen
}
emptyspan<Span:>


Cache::nextFree(spc<u8>,ss<u64*>,shouldhelpgc<u8*>)
{
	s<Span> = this.alloc[spc]
	*shouldhelpgc = false
	freeIndex<u64> = s.nextFreeIndex()

	if freeIndex == s.nelems {
		if s.allocCount != s.nelems {
			os.die("s.allocCount != s.nelems && freeIndex == s.nelems")
		}
		this.refill(spc)
		*shouldhelpgc = true
		s = this.alloc[spc]

		freeIndex = s.nextFreeIndex()
	}

	if freeIndex >= s.nelems {
		os.die("freeIndex is not valid")
	}
	v<u64> = freeIndex* s.elemsize + s.startaddr
	s.allocCount += 1
	if s.allocCount > s.nelems {
		os.die("s.allocCount > s.nelems")
	}
	return v
}
Cache::refill(spc<u8>)
{
	s<Span> = this.alloc[spc]

	if s.allocCount != s.nelems {
		os.die("refill of span with free space remaining\n" )
	}
	if s != &emptyspan {
		if s.sweepgen != heap_.sweepgen + 3 {
			os.die("bad sweepgen in refill\n")
		}
		atomic.store32(&s.sweepgen,heap_.sweepgen)
	}

	s = heap_.centrals[spc].cacheSpan()
	if s == null {
		os.die("out of memory")
	}

	if s.allocCount == s.nelems {
		os.die("span has no free space")
	}

	s.sweepgen = heap_.sweepgen +  3

	this.alloc[spc] =  s
}
func allocmcache(){
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