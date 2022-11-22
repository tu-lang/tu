use std
use std.atomic
use string
use os
use sys

mem Central {
    sys.Mutex*  locks
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
	spanBytes<u64> = class_to_allocnpages[sizeclass(this.sc)] * sys.pageSize

	this.locks.lock()
	traceDone<u8> = false
	sg<u32> = heap_.sweepgen
	
retry:
	s<Span> = null
	for ( s = this.nonempty.first; s != null; s = s.next ) {

		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen,sg - 2,sg - 1) == True {
			this.nonempty.remove(s)
			this.empty.insertback(s)
			this.locks.unlock()
			goto havespan
		}
		if s.sweepgen == sg - 1 {
			continue
		}
		this.nonempty.remove(s)
		this.empty.insertback(s)
		this.locks.unlock()
		goto havespan
	}

	for s = this.empty.first; s != null; s = s.next {
		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen, sg - 2, sg - 1) == True {
			this.empty.remove(s)
			this.empty.insertback(s)
			this.locks.unlock()
			freeIndex<u64> = s.nextFreeIndex()
			if freeIndex != s.nelems {
				s.freeindex = freeIndex
				goto havespan
			}
			this.locks.lock()
			goto retry
		}
		if s.sweepgen == sg - 1 { 
			continue
		}
		break
	}
	this.locks.unlock()

	s = this.grow()
	if s == null {
		return 0.(i8)
	}
	this.locks.lock()
	this.empty.insertback(s)
	this.locks.unlock()

havespan:

	n<i32> = s.nelems - s.allocCount
	if n == 0 || s.freeindex == s.nelems || s.allocCount == s.nelems {
		os.die("span has no free objects")
	}
	atomic.xadd64(&this.nmalloc, n)
	usedBytes<u64> = s.allocCount * s.elemsize
	if sys.gcBlackenEnabled != 0 {
		// heap_live changed.
		//		gcController.revise()
	}
	freeByteBase<u64> = s.freeindex &~ 63
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
	if h.heapBitsForAddr(s.startaddr) == null {
		fmt.println("heapBitsForAddr is null")
	}
	h.initSpan(s)
	return s
}

Central::freeSpan(s<Span> , preserve<u8> , wasempty<u8>)
{
	sg<u32> = heap_.sweepgen

	if  s.sweepgen == sg + 1 || s.sweepgen == sg + 3 {
		os.die("freeSpan given cached span")
	}
	s.needzero = 1

	if preserve {
		if s.list == null {
			os.die("can't preserve unlinked span")
		}
		atomic.store(&s.sweepgen,heap_.sweepgen)
		return 0.(i8)
	}

	this.locks.lock()

	if wasempty {
		this.empty.remove(s)
		this.nonempty.insert(s)
	}

	atomic.store(&s.sweepgen,heap_.sweepgen)

	if s.allocCount != 0 {
		this.locks.unlock()
		return 0.(i8)
	}
	this.nonempty.remove(s)
	this.locks.unlock()
	heap_.freeSpan(s,0.(i8))
	return 1.(i8)
}

Central::uncacheSpan(s<Span>)
{
	if s.allocCount == 0 {
		os.die("uncaching span but s.allocCount == 0")
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
		this.locks.lock()
		this.empty.remove(s)
		this.nonempty.insert(s)
		if  !stale {
		}
		this.locks.unlock()
	}

	if stale {
	}
}