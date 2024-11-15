use std.atomic

Gc::startcycle(){
	if this.gc_trigger <= heapmin {
		this.heapmarked = this.gc_trigger / 2
	}
	
}
Gc::trigger(kind<i32>){
	if !gc.enablegc {
		return False
	}
	if kind == GcAlways {
		return True
	}
	if gcphase != _GCoff {
		return False
	}
	match kind {
		GcHeap: return gc.heaplives >= gc.gc_trigger
		_ : 	return True
	}
}

Gc::markinit(){
	heap_.lock.lock()
	arenas<std.Array> = heap_.allarenas
	heap_.lock.unlock()

	for i<i32> = 0 ; i < arenas.used ; i += 1 {
		ai<u32*> = &arenas.addr[i]
		arr<u64*> = heap_.arenas[arena_l1(*ai)]
		ha<HeapArena> = arr[arena_l2(*ai)]

		total<i64> = pagesPerArena / 8
		for j<i32> = 0 ; j < total ; j += 1{
			ha.pageMarks[j] = 0
		}
	}
	gc.marked = 0
}
Gc::finishsweep(){
	while sweepone() >= Null {
	}

	gbArenas.lock.lock()
	if gbArenas.previous != Null {
		if gbArenas.free == Null {
			gbArenas.free = gbArenas.previous
		}else{
			last<GcBitsArena> = gbArenas.previous
			for(last = gbArenas.previous; last.next != Null; last = last.next){
			}
			last.next = gbArenas.free
			gbArenas.free = gbArenas.previous
		}	
	}

	gbArenas.previous = gbArenas.current
	gbArenas.current = gbArenas.next
	atomic.store64(&gbArenas.next,Null)
	gbArenas.lock.unlock()
}
fn gcmarkhelper(){
	c<Core> = core()
	gc.markscan2(&c.queue)
	
	if atomic.xadd(&sched.stopmark, 1.(i8)) == sched.cores
		sched.allmarkdone.Wake()
}
fn gcsweephelper(){
    while sweepone() >= Null {}

	if atomic.xadd(&sched.stopsweep, 1.(i8)) == sched.cores
		sched.allsweepdone.Wake()
}

Gc::markroot(){
    c<Core> = core()
	// entry of global root stack
	moudleptr<i64*> = moudlestack
	while moudleptr != null {
		subms<i64*> = *moudleptr
		subme<i64*> = *subms

		//OPTIMIZE: align ptr 8 byte
		for ptr<i64*> = subms; ptr <= (subme - 8); ptr += 1 {
			s<Span> = null
			objIndex<u64> = 0
			base<u64> = findObject(*ptr,&s,&objIndex)
			if base != Null {
				tracef(*"root find object: %p(%p) obj:%d",ptr,base,objIndex)
				greyobject(base, s,&c.queue,objIndex)
			}
		}
		//next moudle
		moudleptr = *subme
	}
}

Gc::markroot2(){
    c<Core> = core()
    data1<u64> = &sched
    data1_end<u64> = data1 + sizeof(Sched)
    data2<u64> = &core0
    data2_end<u64> = data2 + sizeof(Core)
	for start<u64*> = data1; start < data1_end; start += ptrSize {
        s<Span> = null
        objIndex<u64> = 0
        base<u64> = findObject(*start,&s,&objIndex)
        if base != Null {
            tracef(*"root find object: %p(%p) obj:%d",start,base,objIndex)
            //DEBUG_SPAN(s)
            greyobject(base, s,&c.queue,objIndex)
        }
	}
    for start<u64*> = data2; start < data2_end; start += ptrSize {
        s<Span> = null
        objIndex<u64> = null
        base<u64> = findObject(*start,&s,&objIndex)
        if base != Null {
            tracef(*"root find object: %p(%p) obj:%d",start,base,objIndex)
            //DEBUG_SPAN(s)
            greyobject(base, s,&c.queue,objIndex)
        }
	}
}

Gc::markscan(){
    _c<Core> = core()
   	for c<Core> = sched.allcores; c != Null ; c = c.link
        c.local.releaseAll()
    for c<Core> = sched.allcores; c != Null ; c = c.link {
        if c.cid == _c.cid continue
        c.helpmark = 1
        if c.status != CoreStop
            dief(*"thread:%d cur:%d not sleep",c.cid,_c.cid)
        c.park.Wake()
	}
    dgc(*"Wake all thread start marking")
    this.markscan2(&_c.queue)
    if atomic.xadd(&sched.stopmark,1.(i8)) != sched.cores {
        sched.allmarkdone.Sleep()
        sched.allmarkdone.Clear()
    }
    dgc(*"all thread mark done")
}

Gc::markscan2(queue<Queue>)
{
    c<Core> = core()
    stk_end<u64> = get_sp()
    debug(*"scan stack range[%p - %p] == %d",stk_end,c.stktop,c.stktop - stk_end)

    cur_sp<u64*> = stk_end
    if c.stktop <= stk_end {
        dief(*"stack error!")
    }
    tracef(*"find object: %p -  %p",cur_sp,c.stktop)
    for cur_sp = stk_end ; cur_sp <= c.stktop ; cur_sp += ptrSize {
        s<Span> = s
        objIndex<u64> = 0
        base<u64> = findObject(*cur_sp,&s,&objIndex)
        if base != 0 {
            tracef(*"find object: %p(%p) obj:%d",cur_sp,base,objIndex)
            //DEBUG_SPAN(s)
            greyobject(base, s,queue,objIndex)
        }
    }

    loop {
        obj<u64> = queue.tryGetFast()
        if obj == Null {
            obj = queue.tryGet()
            if obj == Null
                break
        }
        scanobject(obj,queue) 
    }
}
Gc::marktinys(){
    for c<Core> = sched.allcores; c != Null ; c = c.link {
        cache<Cache> = c.local
		if cache.tiny == 0 continue

        span<Span> = Null
        objIndex<u64> = 0

		findObject(cache.tiny,&span,&objIndex)
        queue<Queue> = &c.queue
		greyobject(cache.tiny,span,queue,objIndex)
	}
}

MarkBits::span_obj(s<Span> , obj<u64>)
{
    u8p<u8*> = s.gcmarkBits + (obj/8)
    mask<u8>  = 1 << (obj%8)
	this.u8p = u8p
	this.mask = mask
	this.index = obj
}
fn objIsUsing(p<u64>){
    s<Span> = null
    objIndex<u64> = 0
    base<u64> = findObject(p,&s,&objIndex)
	if base == 0 return False
	if s.isFree(objIndex) == True {
		return  False
	}else{
		return True
	}
}

fn greyobject(obj<u64> , s<Span> , queue<Queue> , objIndex<u64>)
{
    if obj & (ptrSize - 1) != 0 {
        dief("greyobject: obj not pointer-aligned".(i8))
    }
    if s.isFree(objIndex) == True {
        warn(*"marking free object %p size:%d alloc:%d i:%d",obj,s.elemsize,s.allocCount,objIndex)
        return True
    }
    mbits<MarkBits:> = null
    mbits.span_obj(s,objIndex)
    if mbits.isMarked() == True {
        tracef(*"already marked obj:%p size:%d index:%d bitaddr:%p",obj,s.elemsize,objIndex,mbits.u8p)
        return True
    }
    tracef(*"marke obj:%p size:%d index:%d bitaddr:%p",obj,s.elemsize,objIndex,mbits.u8p)
    mbits.setMarked()

    pageIdx<u64> = null
    pageMask<u8> = null
    arena<HeapArena> = pageIndexOf(s.startaddr,&pageIdx,&pageMask)
    if arena.pageMarks[pageIdx] & pageMask == 0 {
        atomic.or8(&arena.pageMarks[pageIdx], pageMask)
    }
    if (s.sc&1) != Null {
        queue.u8used += s.elemsize
        return True
    }
    if queue.putFast(obj) == False {
        tracef(*"put grey queue. span:%p obj:%p",s,obj)
        queue.put(obj)
    }
}

fn findObject(p<u64>, ss<u64*> , objIndex<u64*>)
{
    *objIndex = 0
    s<Span> = heap_.spanOf(p)
    *ss     = s
    base<u64> = 0
    if  s == Null || p < s.startaddr || p >= s.limit || s.state != mSpanInUse  {
        return Null
    }
    if  s.basemask != 0  {
        base = s.startaddr
        base = base + ((p-base) & s.basemask )
        *objIndex = (base - s.startaddr) >> s.divshift
    } else {
        base = s.startaddr
        if  p-base >= s.elemsize {
            *objIndex = (
                (
                    (p-base) >> s.divshift
                ) * s.divmul
             ) >> s.divshift2
            base += *objIndex * s.elemsize
        }
    }
    return base
}

fn scanobject(b<u64> , queue<Queue>){
    hbits<HeapBits:> = null
    hbits.heapBitsForAddr(b)
    tracef(*"obj:%p bitaddr:%p queue:%p",b,hbits.bitp,queue)
    s<Span> = heap_.spanOf(b)
    n<u64> = s.elemsize
    if n == Null {
        dief(*"scanobject n == 0")
    }

    i<u64> = 0
    for i = 0; i < n ; i += ptrSize {
        if i != 0  {
            hbits.next()
        }
        bits<u32> = hbits.bits()
        if i != 1 * ptrSize && ((bits & bitScan) == 0) {
            break
        }
        if bits&bitPointer == 0 continue
        t_<u64*> = b + i
        obj<u64*> = *t_

        if obj != Null && obj - b >= n {
            s<Span> = Null
            objIndex<u64> = 0
            base<u64> = findObject(obj,&s,&objIndex)
            if base != 0 {
                printf(*"(%p)\t",*obj)
                greyobject(obj,s,queue,objIndex)
            }
        }
    }    
    tracef(*"obj:%p done",b)
    queue.used += n
}



Gc::sweep(){
	debug(*"spans wait sweep:%d gc.forced:%d",heap_.sweepSpans[heap_.sweepgen/2%2].spineLen,this.forced)
	if gcphase != _GCoff {
		dief(*"sweep being done but phase is not GCoff")
	}

	heap_.lock.lock()
	heap_.sweepgen += 2
	heap_.sweepdone = 0
	if heap_.sweepSpans[heap_.sweepgen/2%2].index != 0 {
		dief(*"non-empty swept list")
	}
	heap_.lock.unlock()
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
		if s.sweepgen == sg - 2 && atomic.cas(&s.sweepgen, sg - 2, sg - 1) != False {
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
	gc.spans.free.takeAll(&gc.spans.busy)
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
		heap_.freemanual(span, Null)
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
