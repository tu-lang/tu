use std
use os
use runtime.sys

func coalesce_merge(s<Span> , other<Span>,needsScavenge<u8*>,prescavenged<u64*>)
{
    s.npages += other.npages
    s.needzero |= other.needzero
    if other.startaddr < s.startaddr  {
        s.startaddr = other.startaddr
        heap_.setSpan(s.startaddr,s)
    } else {
        heap_.setSpan(s.startaddr + (s.npages * sys.pageSize - 1),s)
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
func coalesce_realign(a<Span> , b<Span> , other<Span>)
{
    if sys.pageSize <= physPageSize  {
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
    a.npages = (boundary - a.startaddr) / sys.pageSize
    b.npages = (b.startaddr + b.npages * sys.pageSize - boundary) / sys.pageSize
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

	after<Span> = heap_.spanOf(s.startaddr + s.npages * sys.pageSize)
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
	return pha.spans[(p/sys.pageSize)%pagesPerArena]
}
Heap::setSpan(base<u64> , s<Span>)
{
	ai<u32> = arenaIndex(base)
	arr<u64*> = this.arenas[arena_l1(ai)]

	p<HeapArena> = arr[arena_l2(ai)]
	p.spans[(base / sys.pageSize) % pagesPerArena] = s
}
Heap::setSpans(base<u64>,npage<u64>,s<Span> )
{
	p<u64> = base / sys.pageSize
	ai<u32> = arenaIndex(base)
	arr<u64*> = this.arenas[arena_l1(ai)]
	ha<HeapArena> = arr[arena_l2(ai)]

    for n<u64> = 0; n < npage; n += 1  {
		i<u64> = (p + n) % pagesPerArena
        if  i == 0 {
            ai = arenaIndex(base + n * sys.pageSize)
            arr = this.arenas[arena_l1(ai)]
            ha  = arr[arena_l2(ai)]
        }
		ha.spans[i] = s
        // (*ha).spans[i] = s
    }
}
Heap::scavengeLargest(nu8s<u64>){return 0.(i8)}