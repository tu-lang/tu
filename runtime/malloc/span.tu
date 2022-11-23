use std
use runtime.sys
use os

mem Span {
    Span* 	  next
    Span* 	  prev
    Spanlist* list

    u64   startaddr , limit,npages
    u8    state,needzero,scavenged 
    u16   allocCount 
    u32   sweepgen

    i64   unusedsince
    u8    sc

    u16   basemask,divmul
    u8    divshift,divshift2

    u64   elemsize

    u64   freeindex
    u64   nelems
    u8*    allocBits
    u8*    gcmarkBits
    u64    allocCache
}

mem DivMagic{
    u8   shift , shift2
    u16  mul , baseMask
}

Span::isFree(index<u64>)
{
    if(index < this.freeindex){
        return 0.(i8)
    }
	b<u8*>     = this.allocBits
	u8p<u8*> = b + index / 8
	mask<u8>  = 1 << (index % 8)

    return (*u8p & mask ) == 0
}

Span::layout(size<u64*>,n<u64*>,total<u64*>)
{
	*total = this.npages << pageShift
	*size  = this.elemsize
	if ( *size > 0 ){
		*n = *total / *size
	}
}
Span::init(base<u64>,npages<u64>)
{
    this.next = null
    this.prev = null
    this.list = null
    this.startaddr = base
    this.npages = npages
    this.allocCount = 0
    this.sc = 0
    this.elemsize = 0
    this.state = mSpanDead
    this.scavenged = false
    this.needzero = 0
    this.freeindex = 0
    this.allocBits = null
    this.gcmarkBits = null
}
Span::ppbounds(start<u64*>,end<u64*>)
{
    *start = this.startaddr
    *end   = *start + this.npages << pageShift
    if ( physPageSize > sys.pageSize ) {
        *start = (*start + physPageSize - 1) &~ (physPageSize - 1)
        *end   = *end &~ (physPageSize - 1)
    }
}
Span::released()
{
    if !this.scavenged return 0.(i8)
    start<u64> = 0
	end<u64> = 0
    this.ppbounds(&start,&end)

    return end - start
}
Span::scavenge()
{
	start<u64> = 0
	end<u64> = 0
	released<u64> = 0
    this.ppbounds(&start,&end)
    if( end <= start ){
        return 0.(i8)
    }
    released = end - start
    this.scavenged = true
    sys.unused(start,released)
    return released
}
Span::refillAllocCache(whichByte<u64>)
{
	u8s<u8*> = this.allocBits + whichByte
	aCache<u64> = 0
	aCache |= u8s[0]
	aCache |= u8s[1] << 8
	aCache |= u8s[2] << 16
	aCache |= u8s[3] << 24
	aCache |= u8s[4] << 32
	aCache |= u8s[5] << 40
	aCache |= u8s[6] << 48
	aCache |= u8s[7] << 56
	this.allocCache = ~aCache
}

Span::nextFreeIndex()
{
	sfreeindex<u64> = this.freeindex
	snelems<u64>    = this.nelems
	if( sfreeindex == snelems ) {
		return sfreeindex
	}
	if( sfreeindex > snelems ){
		dief("this.freeindex > this.nelems".(i8))
	}

	aCache<u64> = this.allocCache
	bitIndex<i32>  = sys.ctz64(aCache)
	_t<i32> = 63
	while( bitIndex == 64 ){
		sfreeindex = (sfreeindex + 64) &~ _t
		if( sfreeindex >= snelems ){
			this.freeindex = snelems
			return snelems
		}
		whichByte<u64> = sfreeindex / 8
		this.refillAllocCache(whichByte)
		aCache = this.allocCache
		bitIndex = sys.ctz64(aCache)
	}
	result<u64> = sfreeindex + (bitIndex)
	if( result >= snelems ){
		this.freeindex = snelems
		return snelems
	}

	this.allocCache >>= bitIndex + 1
	sfreeindex = result + 1

	if (sfreeindex%64 == 0 && sfreeindex != snelems ){
		whichByte<u64> = sfreeindex / 8
		this.refillAllocCache(whichByte)
	}
	this.freeindex = sfreeindex
	return result
}

Spanlist::remove(s<Span>)
{
	if ( s.list != this ) {
		dief("mSpanList.remove".(i8))
	}
	if ( this.first == s ) {
		this.first = s.next
	} else {
		s.prev.next = s.next
	}
	if ( this.last == s ){
		this.last = s.prev
	} else {
		s.next.prev = s.prev
	}
	s.next = null
	s.prev = null
	s.list	= null
}

Spanlist::insertback(s<Span>)
{
	if ( s.next != null || s.prev != null || s.list != null ){
		dief("mSpanList.insertBack".(i8))
	}
	s.prev = this.last
	if ( this.last != null ){
		this.last.next = s
	} else {
		this.first = s
	}
	this.last = s
	s.list = this
}

Spanlist::insert(s<Span>)
{
	if(s.startaddr == 0)
		dief("s is unalloced!".(i8))
	if (s.next != null || s.prev != null || s.list != null){
		dief("mSpanList.insert".(i8))
	}
	s.next = this.first
	if ( this.first != null ){
		this.first.prev = s
	} else {
		this.last = s
	}
	this.first = s
	s.list = this
}

Span::nextFreeFast()
{
	theBit<i32> = sys.ctz64(this.allocCache)
	if theBit < 64  {
		result<u64> = this.freeindex + (theBit)
		if( result < this.nelems ){
			freeidx<u64> = result + 1
			if( freeidx%64 == 0 && freeidx != this.nelems ){
				return 0.(i8)
			}
			this.allocCache >>= theBit + 1
			this.freeindex = freeidx
			this.allocCount += 1
			return (result * this.elemsize) + this.startaddr
		}
	}
	return 0.(i8)
}
