use std.atomic

Gc::sweep(){
	debug(*"spans wait sweep:%d gc.forced:%d",heap_.sweepSpans[heap_.sweepgen/2%2].spineLen,this.forced)
	if gcphase != _GCoff {
		dief(*"sweep being done but phase is not GCoff")
	}

	heap_.locks.lock()
	heap_.sweepgen += 2
	heap_.sweepdone = 0
	if heap_.sweepSpans[heap_.sweepgen/2%2].index != 0 {
		dief(*"non-empty swept list")
	}
	heap_.locks.unlock()
	c_<Core> = core()
	for c<Core> = sched.allcores; c != Null ; c = c.link {
		if c.cid == c_.cid continue
		c.helpsweep = 1
		if c.status != CoreStop
			dief(*"thread:%d cur:%d not sleep",c.cid,core().cid)
		c.park.Wake()
	}		
	dgc(*"Wake all thread sweeping")
	while sweepone() >= Null {}
	if atomic.xadd(&sched.stopsweep,1.(i8)) != sched.cores {
		sched.allsweepdone.Sleep()
		sched.allsweepdone.Clear()
	}
	dgc(*"Wake all thread done")
	this.prepareflush()
	while this.flush(Null) == True {}
}

fn sweepone(){
	s<Span> = null 
	sg<u32> = heap_.sweepgen
	debug(*"heap_.sweepdone:%d i:%d wait:%d",heap_.sweepdone,1-sg/2%2,heap_.sweepSpans[1-sg/2%2].spineLen)
	if heap_.sweepdone != 0 {
		return -1.(i8)
	}
	atomic.xadd(&heap_.sweepers, 1.(i8))

	loop {
		s = heap_.sweepSpans[1-sg/2%2].pop()
		if s == Null {
			debug(*"sweepdone")
			atomic.store(&heap_.sweepdone, 1.(i8))
			break
		}
		if s.state != mSpanInUse {

			if s.sweepgen == sg || s.sweepgen == sg+3 {
			}else {
				dief(*"non in-use span in unswept list")
			}
			continue
		}
		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen, sg - 2, sg - 1) {
			break
		}
	}

	npages<i64> = -1
	if s != Null {
		npages = s.npages
		if s.sweep(False) == True {
		} else {
			npages = 0
		}
	}
	atomic.xadd(&heap_.sweepers, -1.(i8))
	return npages
}

fn bgsweep()
{
	debug(*"bgsweep")
	loop { while( sweepone() >= Null ){} }
}

Gc::prepareflush() {
	gc.spans.lock.lock()
	if (gc.full.self != 0) {
		dief(*"cannot free Bufs when work.full != 0")
	}
	gc.empty.self = 0
	//GCTODO:
	//gc.spans.free.takeAll(&gc.spans.busy)
	gc.spans.lock.unlock()
}

batchSize<i64> = 64 // ~1–2 µs per span.
Gc::flush(preempt<i32>) {
	this.spans.lock.lock()
	if gcphase != _GCoff || this.spans.free.isEmpty() == True {
		this.spans.lock.unlock()
		return False
	}
	for i<i32> = 0; i < batchSize && !preempt; i += 1 {
		span<Span> = this.spans.free.first
		if span == Null {
			break
		}
		this.spans.free.remove(span)
		//GCTODO:
		//heap_.freeManual(span, Null)
	}
	more<i32> = !this.spans.free.isEmpty()
	this.spans.lock.unlock()
	return more
}

Span::sweep(preserve<i32>)
{
	//DEBUG_SPAN(this)
	h<Heap> = &heap_
	sweepgen<u32> = h.sweepgen
	if this.state != mSpanInUse || this.sweepgen != sweepgen - 1  {
		dief(*"mspan.sweep: bad span state")
	}

	spc<u8> = this.sc
	size<u64>  = this.elemsize
	res<i32> 	  = false
	c_<Core> = core()
	c<Cache> = c_.local
	freeToHeap<i32> = false

	nalloc<u16> = this.countAlloc()
	if sizeclass(spc) == Null && nalloc == Null {
		this.needzero = 1
		freeToHeap = true
	}
	nfreed<u64> = this.allocCount - nalloc
	if nalloc > this.allocCount {
		dief(*"sweep increased allocation count nalloc:%d allcount:%d",nalloc,this.allocCount)
	}

	this.allocCount = nalloc
	wasempty<i32> = this.nextFreeIndex() == this.nelems
	this.freeindex  = 0

	this.allocBits  = this.gcmarkBits
	this.gcmarkBits = newMarkBits(this.nelems)

	this.refillAllocCache(Null)

	if( freeToHeap || nfreed == 0 ){
		if( this.state != mSpanInUse || this.sweepgen != sweepgen - 1 ){
			dief(*"mspan.sweep: bad span state after sweep")
		}
		atomic.store(&this.sweepgen,sweepgen)
	}
	tracef(*"span:%p nfreed:%d sc:%d freeToHeap:%d",this,nfreed,sizeclass(spc),freeToHeap)
	if( nfreed > 0 && sizeclass(spc) != Null ){
		c.local_nsmallfree[sizeclass(spc)] += nfreed

		res = h.centrals[spc].freeSpan(this,preserve, wasempty)
	} else if( freeToHeap ){
		heap_.freeSpan(this,True)
		res = true
	}
	//DEBUG_SPAN(this)
	if( !res ){
		h.sweepSpans[sweepgen/2%2].push(this)
	}
	return res
}

Span::countAlloc()
{
	count<i32> = 0
	maxIndex<u64> = this.nelems / 8
	for i<u64> = 0; i < maxIndex; i += 1{
		mrkBits<u8> = this.gcmarkBits[i]
		count += oneBitCount[mrkBits]
	}
	bitsInLastByte<u64> = this.nelems % 8
	if ( bitsInLastByte != 0 )
	{
		mrkBits<u8> = this.gcmarkBits[maxIndex]
		mask<u8> 	  = (1 << bitsInLastByte) - 1	
		bits<u8> 	  = mrkBits & mask
		count += oneBitCount[bits]
	}
	return count
}
