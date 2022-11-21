use std
use std.atomic
use os
use fmt
use sys

mem Heap {
    sys.Mutex       locks

    Treap       free
    Treap       scav

    std.Array   allspans
    // GcSweepBuf   sweepSpans[2]
    sys.Fixalloc    spanalloc
    sys.Fixalloc    cachealloc
    sys.Fixalloc    treapalloc
    sys.Fixalloc    specialfinalizeralloc
    sys.Fixalloc    specialprofilealloc
    sys.Fixalloc    arenaHintAlloc
    sys.LinearAlloc arena
    ArenaHint*   arenaHints
    HeapArena*   arenas[1 << arenaL1Bits]

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

heap_<Heap:> 

func recordspan(vh<Heap>, p<Span>) {
    vh.allspans.push(p)
}

Heap::init(){
    this.treapalloc.init(sizeof(TreapNode),0.(i8),0.(i8))
    this.spanalloc.init(sizeof(Span),recordspan,this)
    this.cachealloc.init(sizeof(Cache),0.(i8),0.(i8))

    this.specialfinalizeralloc.init(0.(i8),0.(i8),0.(i8))
    this.specialprofilealloc.init(0.(i8),0.(i8),0.(i8))
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
    this.locks.lock()
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
    this.locks.unlock()
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
        return null
    }
    s = heap_.pickFreeSpan(npage)
    if ( s != null ) {
        goto haveSpan
    }
    os.die("grew heap, but no adequate free span found")

haveSpan:
    if (s.state != mSpanFree ) {
        os.die("candidate Mspan for allocation is not free")
    }
    if (s.npages < npage ) {
        os.die("candidate Mspan for allocation is too small")
    }
    if (s.npages > npage ) {
        t = this.spanalloc.alloc()
        t.init(s.startaddr+(npage<<pageShift),s.npages-npage)
        s.npages = npage
        this.setSpan(t.startaddr - 1,s)
        this.setSpan(t.startaddr,t)
        this.setSpan(t.startaddr+t.npages * sys.pageSize - 1,t)

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
        sys.used(s.startaddr, s.npages<<pageShift)
        s.scavenged = false
    }
    s.unusedsince = 0

    heap_.setSpan(s.startaddr,s)

    if (s.list != null)
        os.die("still in list")
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
        fmt.printf("runtime: out of memory: cannot allocate %ld -u8 block (%ld in use)\n",ask,0)
        return 0.(i8)
    }

    heap_.scavengeLargest(size)
    s<Span> = this.spanalloc.alloc()
    s.init(v,size/sys.pageSize)

    heap_.setSpans(s.startaddr,s.npages,s)
    s.sweepgen = this.sweepgen
    s.state = mSpanInUse
    this.pagesInuse += s.npages
    heap_.freeSpanLocked(s,0.(i8),1.(i8),0)
    return 1.(i8)
}


Heap::freeSpanLocked(s<Span>,acctinuse<u8>,acctidle<u8>,unusedsince<i64>)
{
	match s.state {
	    mSpanManual:{
		    if ( s.allocCount != 0 ) {
			    os.die("mheap.freeSpanLocked - invalid stack free")
		    }
        }
	    mSpanInUse:{
		    if ( s.allocCount != 0 || s.sweepgen != this.sweepgen ) {
			    os.die("mheap.freeSpanLocked - invalid free")
		    }
		    this.pagesInuse -= (s.npages)

            pageIdx<u64> = 0
            pageMask<u8> = 0
            arena<HeapArena> = pageIndexOf(s.startaddr,&pageIdx,&pageMask)
		    arena.pageInuse[pageIdx] = arena.pageInuse[pageIdx] &~ pageMask
        }
	    _:{
		    os.die("mheap.freeSpanLocked - invalid span state")
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
    g<sys.Coroutine> = getg()
    mp<sys.Core> = g.m
    this.locks.lock()
    mp.mcache.local_scan = 0

    mp.mcache.local_tinyallocs = 0
    if sys.gcBlackenEnabled != 0 {
    }
    heap_.freeSpanLocked(s,1.(i8),1.(i8),0.(i8))
    this.locks.unlock()
}

Heap::allocManual(npage<u64>)
{
	this.locks.lock()
    s<Span> = heap_.allocSpanLocked(npage)
	if ( s != null) {
		s.state = mSpanManual
		s.allocCount = 0
		s.sc = 0
		s.nelems = 0
		s.elemsize = 0
		s.limit = s.startaddr + s.npages << pageShift
	}

	this.locks.unlock()
	return s
}