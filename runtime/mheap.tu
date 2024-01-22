use std
use std.atomic
use os
use fmt

mem Heap {
    MutexInter  lock
    Treap       free
    Treap       scav
    std.Array   allspans
	std.Array 	allarenas
	std.Array 	sweeparenas
    Stack   sweepSpans[2]

    Fixalloc    spanalloc
    Fixalloc    cachealloc
    Fixalloc    treapalloc
    Fixalloc    specialfinalizeralloc
    Fixalloc    specialprofilealloc
    Fixalloc    arenaHintAlloc
    LinearAlloc arena
    ArenaHint*  arenaHints
	//TODOGC:
    HeapArena*  arenas[1 << arenaL1Bits]
    u64      scavengeCredit
    u32      sweepgen
    u32      sweepdone
    u32      sweepers
    u64*     dweepSpans
    u64      pagesInuse
    u64      largealloc
    u64      nlargealloc
    Central  centrals[numSpanClasses]
}

fn recordspan(h<Heap> , s<Span>) {
	//allaspans should not be used when mallocinit not finish
	//h.allspans.push(s)
}

Heap::init(){
    this.treapalloc.init(sizeof(TreapNode),0.(i8),0.(i8))
    this.spanalloc.init(sizeof(Span),recordspan,this)
    this.cachealloc.init(sizeof(Cache),0.(i8),0.(i8))

    this.arenaHintAlloc.init(sizeof(ArenaHint),0.(i8),0.(i8))

    for i<i32> = 0 ; i < numSpanClasses ;i += 1{
        this.centrals[i].init(i)
    }
}

Heap::alloc(npage<u64>, spanclass<u8> , large<u8> , needzero<u8>)
{
    s<Span> = this.alloc_m(npage,spanclass,large)
    if s != null {
        if needzero && s.needzero != 0 
            std.memset(s.startaddr,0.(i8),s.npages << pageShift)
        s.needzero = 0
    }
    return s
}
Heap::alloc_m(npage<u64>,spanc<u8>,large<u8>)
{
    this.lock.lock()
    s<Span> = heap_.allocSpanLocked(npage)
	if  s != null {
        atomic.store(&s.sweepgen,this.sweepgen)
		s.state = mSpanInUse
		s.allocCount = 0
		s.sc  = spanc
		sc<i8> = sizeclass(spanc)
		if ( sc == 0 ) {
			s.elemsize = s.npages << pageShift
			s.divshift = 0
			s.divmul   = 0
			s.divshift2 = 0
			s.basemask = 0
		} else {
			s.elemsize = class_to_size[sc]
            //FIXME: &class_to_divmagic[sc]

            m<DivMagic> = &class_to_divmagic + sizeof(DivMagic) * sc
			s.divshift = m.shift
			s.divmul   = m.mul
			s.divshift2 = m.shift2
			s.basemask = m.baseMask
		}

        pageIdx<u64> = 0
        pageMask<u8> = 0
        arena<HeapArena> = pageIndexOf(s.startaddr,&pageIdx,&pageMask)
		arena.pageInuse[pageIdx] |= pageMask

		this.pagesInuse += npage
		if large {
		    this.largealloc  += s.elemsize
		    this.nlargealloc += 1
		}
	}
    this.lock.unlock()
	return s
}
Heap::allocSpanLocked(npage<u64>)
{
    s<Span> = heap_.pickFreeSpan(npage)
    t<Span> = null
    if( s != null ){
        goto haveSpan
    }

    if heap_.grow(npage) != True {
        return 0.(i8)
    }
    s = heap_.pickFreeSpan(npage)
    if ( s != null ) {
        goto haveSpan
    }
    dief("grew heap, but no adequate free span found".(i8))

haveSpan:
    if (s.state != mSpanFree ) {
        dief("candidate Mspan for allocation is not free".(i8))
    }
    if (s.npages < npage ) {
        dief("candidate Mspan for allocation is too small".(i8))
    }
    if (s.npages > npage ) {
        t = this.spanalloc.alloc()
        t.init(s.startaddr+(npage<<pageShift),s.npages-npage)
        s.npages = npage
        this.setSpan(t.startaddr - 1,s)
        this.setSpan(t.startaddr,t)
        this.setSpan(t.startaddr+t.npages * pageSize - 1,t)

        t.needzero = s.needzero

        start<u64> = 0
        end<u64> = 0
        t.ppbounds(&start,&end)

        if (s.scavenged && start < end ) {
            t.scavenged = true
        }
        s.state = mSpanManual 
        t.state = mSpanManual
        heap_.freeSpanLocked(t,0.(i8),0.(i8),s.unusedsince)
        s.state = mSpanFree
    }
    if (s.scavenged ) {
        sys_used(s.startaddr, s.npages<<pageShift)
        s.scavenged = false
    }
    s.unusedsince = 0

    heap_.setSpan(s.startaddr,s)

    if (s.list != null)
        dief("still in list".(i8))
    return s
}

Heap::pickFreeSpan(npage<u64>){

    tf<TreapNode> = this.free.find(npage)
    ts<TreapNode> = this.scav.find(npage)

    s<Span> = null
    if ( tf != null && (ts == null || tf.spankey.npages <= ts.spankey.npages)) {
        s = tf.spankey
        this.free.removeNode(tf)
    } else if ( ts != null && (tf == null || tf.spankey.npages > ts.spankey.npages) ) {
        s = ts.spankey
        this.scav.removeNode(ts)
    }
    return s
}
Heap::grow(npage<u64>)
{
    ask<u64> = npage << pageShift
    v<u64> = 0
    size<u64> = 0
    v = this.sysAlloc(ask,&size)
    if ( v == 0) {
        debug("runtime: out of memory: %d\n".(i8),npage)
        debug("runtime: out of memory: %d\n".(i8),pageShift)
        return 0.(i8)
    }

    heap_.scavengeLargest(size)
    s<Span> = this.spanalloc.alloc()
    s.init(v,size / pageSize)

    heap_.setSpans(s.startaddr,s.npages,s)
    s.sweepgen = this.sweepgen
    s.state = mSpanInUse
    this.pagesInuse += s.npages
    heap_.freeSpanLocked(s,0.(i8),1.(i8),0.(i8))
    return 1.(i8)
}


Heap::freeSpanLocked(s<Span>,acctinuse<u8>,acctidle<u8>,unusedsince<i64>)
{
	match s.state {
	    mSpanManual:{
		    if ( s.allocCount != 0 ) {
			    dief("mheap.freeSpanLocked - invalid stack free".(i8))
		    }
        }
	    mSpanInUse:{
		    if ( s.allocCount != 0 || s.sweepgen != this.sweepgen ) {
			    dief("mheap.freeSpanLocked - invalid free".(i8))
		    }
		    this.pagesInuse -= (s.npages)

            pageIdx<u64> = 0
            pageMask<u8> = 0
            arena<HeapArena> = pageIndexOf(s.startaddr,&pageIdx,&pageMask)
		    arena.pageInuse[pageIdx] = arena.pageInuse[pageIdx] &~ pageMask
        }
	    _:{
		    dief("mheap.freeSpanLocked - invalid span state".(i8))
        }
	}

	s.state = mSpanFree

	s.unusedsince = unusedsince
	if ( unusedsince == 0 ) {
	}

	heap_.coalesce(s)

	if ( s.scavenged ) {
        this.scav.insert(s)
	} else {
        this.free.insert(s)
	}
}
Heap::freeSpan(s<Span> , large<u8>)
{
    c<Core> = core()
    this.lock.lock()
    c.local.local_scan = 0

    c.local.local_tinyallocs = 0
    if gcBlackenEnabled != 0 {
    }
    heap_.freeSpanLocked(s,1.(i8),1.(i8),0.(i8))
    this.lock.unlock()
}

Heap::allocManual(npage<u64>)
{
	this.lock.lock()
    s<Span> = heap_.allocSpanLocked(npage)
	if ( s != null) {
		s.state = mSpanManual
		s.allocCount = 0
		s.sc = 0
		s.nelems = 0
		s.elemsize = 0
		s.limit = s.startaddr + s.npages << pageShift
	}

	this.lock.unlock()
	return s
}

fn coalesce_merge(s<Span> , other<Span>,needsScavenge<u8*>,prescavenged<u64*>)
{
    s.npages += other.npages
    s.needzero |= other.needzero
    if other.startaddr < s.startaddr  {
        s.startaddr = other.startaddr
        heap_.setSpan(s.startaddr,s)
    } else {
        heap_.setSpan(s.startaddr + (s.npages * pageSize - 1),s)
    }

    *needsScavenge = *needsScavenge || other.scavenged || s.scavenged
    *prescavenged += other.released()
    if ( other.scavenged ) {
		heap_.scav.removeSpan(other)
    } else {
		heap_.free.removeSpan(other)
    }
    other.state = mSpanDead
	heap_.spanalloc.free(other)
}
fn coalesce_realign(a<Span> , b<Span> , other<Span>)
{
    if pageSize <= physPageSize  {
        return 0.(i8)
    }
    if ( other.scavenged ) {
		heap_.scav.removeSpan(other)
    } else {
		heap_.free.removeSpan(other)
    }
	boundary<u64> = b.startaddr
    if  a.scavenged  {
        boundary = boundary &~ (physPageSize - 1)
    } else {
        boundary = (boundary + physPageSize - 1) &~ (physPageSize - 1)
    }
    a.npages = (boundary - a.startaddr) / pageSize
    b.npages = (b.startaddr + b.npages * pageSize - boundary) / pageSize
    b.startaddr = boundary

    heap_.setSpan(boundary - 1, a)
    heap_.setSpan(boundary, b)

    if other.scavenged  {
		heap_.scav.insert(other)
    } else {
		heap_.free.insert(other)
    }
}
Heap::coalesce(s<Span>)
{
	needsScavenge<u8> = false

	prescavenged<u64> = s.released()
	before<Span> = heap_.spanOf(s.startaddr - 1)
	if  before != null && before.state == mSpanFree
	{
		if  s.scavenged == before.scavenged  {
			coalesce_merge(s,before,&needsScavenge,&prescavenged)
		} else {
		    coalesce_realign(before,s,before)
		}
	}

	after<Span> = heap_.spanOf(s.startaddr + s.npages * pageSize)
    if  after != null && after.state == mSpanFree  {
		if  s.scavenged == after.scavenged  {
			coalesce_merge(s,after,&needsScavenge,&prescavenged)
		} else {
			coalesce_realign(s,after,after)
		}
	}

	if  needsScavenge  {
		s.scavenge()
	}
}

Heap::spanOf(p<u64>)
{
	ri<u32> = arenaIndex(p)
	if  arenaL1Bits == 0  {
		if  arena_l2(ri) >= ( 1 << arenaL2Bits ) {
			return 0.(i8)
		}
	}
	l2<u64*> = heap_.arenas[arena_l1(ri)]
	if arenaL1Bits != 0 && l2 == null  { 
		debug("span not exist!".(i8))
		return 0.(i8)
	}
	pha<HeapArena> = l2[arena_l2(ri)]
	if pha == null {
		return 0.(i8)
	}
	return pha.spans[(p / pageSize)%pagesPerArena]
}
Heap::setSpan(base<u64> , s<Span>)
{
	ai<u32> = arenaIndex(base)
	arr<u64*> = this.arenas[arena_l1(ai)]

	p<HeapArena> = arr[arena_l2(ai)]
	p.spans[(base / pageSize) % pagesPerArena] = s
}
Heap::setSpans(base<u64>,npage<u64>,s<Span> )
{
	p<u64> = base / pageSize
	ai<u32> = arenaIndex(base)
	arr<u64*> = this.arenas[arena_l1(ai)]
	ha<HeapArena> = arr[arena_l2(ai)]

    for n<u64> = 0; n < npage; n += 1  {
		i<u64> = (p + n) % pagesPerArena
        if  i == 0 {
            ai = arenaIndex(base + n * pageSize)
            arr = this.arenas[arena_l1(ai)]
            ha  = arr[arena_l2(ai)]
        }
		ha.spans[i] = s
        // (*ha).spans[i] = s
    }
}
Heap::scavengeLargest(nu8s<u64>){return 0.(i8)}

Heap::sysAlloc(n<u64> , ssize<u64*>)
{
	size<u64> = 0
	n = round(n, heapArenaBytes)

	v<u64*> = this.arena.alloc(n,heapArenaBytes)
	if v != null {
		size = n
		goto mapped
	}

	while this.arenaHints != null {
		hint<ArenaHint> = this.arenaHints
		p<u64> = hint.addr
		if hint.down {
			p -= n
		}
		if( p+n < p ){
			v = null
		} else if arenaIndex(p + n - 1) >= 1 << arenaBits {
			v = null
		} else {
			v = sys_reserve(p, n)
		}
		if( p == v ){
			if !hint.down {
				p += n
			}
			hint.addr = p
			size = n
			break
		}
		if v != null {
			sys_free(v, n)
		}
		this.arenaHints = hint.next
		this.arenaHintAlloc.free(hint)
	}

	if size == 0 {
		v<u64*> = 0
		size<u64> = n

		v = reserveAligned(0.(i8),&size,heapArenaBytes)
		if( v == null ){
			*ssize = 0
			return 0.(i8)
		}
		hint<ArenaHint> = this.arenaHintAlloc.alloc()
		hint.addr = v
		hint.down = true
		hint.next = this.arenaHints
		this.arenaHints = hint

		hint = this.arenaHintAlloc.alloc()
		hint.addr = v + size
		hint.down = true
		hint.next = this.arenaHints
		this.arenaHints = hint
	}

	bad<i32> = 0
	p<u64> = v
	if( p+size < p ){
		bad = 1
		//"region exceeds u64 range"
	} else if( arenaIndex(p) >= 1<<arenaBits ){
		bad = 1
		//"base outside usable address space"
	} else if( arenaIndex(p+size - 1) >= 1<<arenaBits ){
		bad = 1
		//"end outside usable address space"
	}
	// if( bad != "" ){
	if bad {
		dief("memory reservation exceeds address space limit".(i8))
	}

	if v&(heapArenaBytes - 1) != 0  {
		dief("misrounded allocation in sysAlloc".(i8))
	}

	sys_map(v,size)

mapped: 
	for ri<u32> = arenaIndex(v); ri <= arenaIndex(v+size - 1); ri += 1  {
		l2<u64*> = this.arenas[arena_l1(ri)]
		if l2 == null {
			l2 = sys_fixalloc( 1 << arenaL2Bits * ptrSize,ptrSize)
			if l2 == null {
				dief("out of memory allocating heap arena map".(i8))
			}
			atomic.store64(&this.arenas[arena_l1(ri)],l2)
		}
		if l2[arena_l2(ri)] != null {
			dief("arena already initialized".(i8))
		}
		r<HeapArena> = 0
        r = sys_fixalloc(sizeof(HeapArena), ptrSize)
        if r == null {
            dief("out of memory allocating heap arena metadata".(i8))
        }
		//OPTIMIZE:
		atomic.store64(l2 + arena_l2(ri) * ptrSize, r)
	}

    *ssize = size
	return v
}

Heap::isSweepDone(){
    return this.sweepdone != 0
}

Heap::freemanual(s<Span> , stat<u64*>){
	s.needzero = 1
    this.lock.lock()
	this.freeSpanLocked(s, False, True, Null)
    this.lock.unlock()
}
