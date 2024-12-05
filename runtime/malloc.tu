use os
use std

class_to_divmagic<DivMagic:67> = [
    {0, 0, 0, 0},     {3, 0, 1, 65528}, {4, 0, 1, 65520}, {5, 0, 1, 65504}, {4, 9, 171, 0}, 
    {6, 0, 1, 65472}, {4, 10, 205, 0}, {5, 9, 171, 0}, {4, 11, 293, 0}, {7, 0, 1, 65408}, 
    {4, 9, 57, 0},    {5, 10, 205, 0},  {4, 12, 373, 0}, {6, 7, 43, 0}, {4, 13, 631, 0}, 
    {5, 11, 293, 0},  {4, 13, 547, 0}, {8, 0, 1, 65280}, {5, 9, 57, 0}, {6, 9, 103, 0}, 
    {5, 12, 373, 0},  {7, 7, 43, 0}, {5, 10, 79, 0}, {6, 10, 147, 0}, {5, 11, 137, 0}, 
    {9, 0, 1, 65024}, {6, 9, 57, 0}, {7, 6, 13, 0}, {6, 11, 187, 0}, {8, 5, 11, 0},
    {7, 8, 37, 0},    {10, 0, 1, 64512}, {7, 9, 57, 0}, {8, 6, 13, 0}, {7, 11, 187, 0},
    {9, 5, 11, 0},    {8, 8, 37, 0}, {11, 0, 1, 63488}, {8, 9, 57, 0}, {7, 10, 49, 0},
    {10, 5, 11, 0},   {7, 10, 41, 0}, {7, 9, 19, 0}, {12, 0, 1, 61440}, {8, 9, 27, 0}, 
    {8, 10, 49, 0},   {11, 5, 11, 0}, {7, 13, 161, 0}, {7, 13, 155, 0}, {8, 9, 19, 0}, 
    {13, 0, 1, 57344}, {8, 12, 111, 0}, {9, 9, 27, 0}, {11, 6, 13, 0}, {7, 14, 193, 0}, 
    {12, 3, 3, 0},    {8, 13, 155, 0}, {11, 8, 37, 0}, {14, 0, 1, 49152}, {11, 8, 29, 0},
    {7, 13, 55, 0},   {12, 5, 7, 0}, {8, 14, 193, 0}, {13, 3, 3, 0}, {7, 14, 77, 0}, 
    {12, 7, 19, 0},   {15, 0, 1, 32768}
]

size_to_class8<u8 : 129> = [
    0, 1, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14,
    14, 15, 15, 16, 16, 17, 17, 18, 18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21,
    21, 22, 22, 22, 22, 23, 23, 23, 23, 24, 24, 24, 24, 25, 25, 25, 25, 26, 26, 26, 26, 26, 
    26, 26, 26, 27, 27, 27, 27, 27, 27, 27, 27, 28, 28, 28, 28, 28, 28, 28, 28, 29, 29, 29, 
    29, 29, 29, 29, 29, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 31,
    31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31, 31
]
size_to_class128<u8 : 249> = [
    31, 32, 33, 34, 35, 36, 36, 37, 37, 38, 38, 39, 39, 39, 40, 40, 40, 41, 42, 42, 43, 43, 
    43, 43, 43, 44, 44, 44, 44, 44, 44, 45, 45, 45, 45, 46, 46, 46, 46, 46, 46, 47, 47, 47, 
    48, 48, 49, 50, 50, 50, 50, 50, 50, 50, 50, 50, 50, 51, 51, 51, 51, 51, 51, 51, 51, 51, 
    51, 52, 52, 53, 53, 53, 53, 54, 54, 54, 54, 54, 55, 55, 55, 55, 55, 55, 55, 55, 55, 55, 
    55, 56, 56, 56, 56, 56, 56, 56, 56, 56, 56, 57, 57, 57, 57, 57, 57, 58, 58, 58, 58, 58, 
    58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 58, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 59, 
    59, 59, 59, 59, 59, 60, 60, 60, 60, 60, 61, 61, 61, 61, 61, 61, 61, 61, 61, 61, 61, 62, 
    62, 62, 62, 62, 62, 62, 62, 62, 62, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 63, 
    63, 63, 63, 63, 63, 63, 63, 63, 63, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 64, 
    64, 64, 64, 64, 64, 64, 64, 64, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 65, 66, 66, 66, 
    66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 66, 
    66, 66, 66, 66, 66, 66, 66
]
class_to_size<u16 : 67> =  [ 
    0, 8, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176, 192, 208, 224, 240, 256, 288, 320, 
    352, 384, 416, 448, 480, 512, 576, 640, 704, 768, 896, 1024, 1152, 1280, 1408, 1536, 1792, 
    2048, 2304, 2688, 3072, 3200, 3456, 4096, 4864, 5376, 6144, 6528, 6784, 6912, 8192, 9472, 
    9728, 10240, 10880, 12288, 13568, 14336, 16384, 18432, 19072, 20480, 21760, 24576, 27264, 
    28672, 32768
]
class_to_allocnpages<u8:67> = [
    0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 
    1, 1, 1, 1, 2, 1, 2, 1, 2, 1, 3, 2, 3, 1, 3, 2, 3, 4, 5, 6, 1, 7, 6, 5, 4, 3, 5, 7, 2, 9, 
    7, 5, 8, 3, 10, 7, 4
]

oneBitCount<u8:256> = [
	0, 1, 1, 2, 1, 2, 2, 3,
	1, 2, 2, 3, 2, 3, 3, 4,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	1, 2, 2, 3, 2, 3, 3, 4,
	2, 3, 3, 4, 3, 4, 4, 5,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	2, 3, 3, 4, 3, 4, 4, 5,
	3, 4, 4, 5, 4, 5, 5, 6,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	3, 4, 4, 5, 4, 5, 5, 6,
	4, 5, 5, 6, 5, 6, 6, 7,
	4, 5, 5, 6, 5, 6, 6, 7,
	5, 6, 6, 7, 6, 7, 7, 8
]

fn large_alloc(size<u64>, needzero<u8> , noscan<u8>)
{
	if size + pageSize < size {
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


fn malloc(size<u64> , noscan<u8> , needzero<u8>)
{
	if size == 0 {
		//only this can use dynamic grammer,cos it's easy to backtrace
		dief(*"malloc size == 0\n")
	}
	if( gcphase != _GCoff){}
	if( gcBlackenEnabled != 0 ){}
	c_<Core> = core()
	if( c_.mallocing != 0 ){ 
		dief("malloc deadlock\n".(i8))
	}
	c_.mallocing = 1
	shouldgc<u8> = false
	dataSize<u64>  = size

	c<Cache> = c_.local
	x<u64*> = null
	if( size <= maxSmallSize ){ 
		// if( noscan && size < maxTinySize ){
		// 	off<u64> = c.tinyoffset
		// 	if( size&7 == 0 ) {
		// 		off = round(off, 8.(i8))
		// 	} else if( size&3 == 0 ){
		// 		off = round(off, 4.(i8))
		// 	} else if( size&1 == 0 ){
		// 		off = round(off, 2.(i8))
		// 	}
		// 	if( off+size <= maxTinySize && c.tiny != 0 ){
		// 		x = (c.tiny + off)
		// 		c.tinyoffset = off + size
		// 		c.local_tinyallocs += 1
		// 		c_.mallocing = 0
		// 		return x
		// 	}
		// 	s<Span> = c.alloc[tinySpanClass]
		// 	v<u64> = s.nextFreeFast()
		// 	if( v == 0 ) {
		// 		v = c.nextFree(tinySpanClass,&s,&shouldgc)
		// 	}
		// 	x = v
		// 	//clear 16 bits
		// 	x[0] = 0
		// 	x[1] = 0
		// 	if( size < c.tinyoffset || c.tiny == 0 ){
		// 		c.tiny = x
		// 		c.tinyoffset = size
		// 	}
		// 	size = maxTinySize
		// } else {
			sz<u8> = 0
			if( size <= smallSizeMax - 8 ){
				sz = size_to_class8[(size+smallSizeDiv - 1)/smallSizeDiv]
			} else {
				sz = size_to_class128[(size-smallSizeMax+largeSizeDiv - 1)/largeSizeDiv]
			}
			size = (class_to_size[sz])
			spc<u8> = makeSpanClass(sz, noscan)
			s<Span> = c.alloc[spc]
			v<u64> = s.nextFreeFast()
			if( v == 0 ){
				v = c.nextFree(spc,&s,&shouldgc)
			}
			x = v
			if( needzero && s.needzero != 0 ){
				std.memset(v,0.(i8),size)
			}
		// }
	} else {
		s<Span> = null
		shouldgc = true
		s = large_alloc(size,needzero,noscan)
		s.freeindex = 1
		s.allocCount = 1
		x = s.startaddr
		size = s.elemsize
	}
	scanSize<u64> = null
	if !noscan  {
		scanSize = size
		c.local_scan += scanSize
	}
	c_.mallocing = 0 
	if shouldgc {
		gc.start(GcHeap)
	}
	return x
}

mem Spanlist {
    Span* first
    Span* last
}

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

Span::debug() {
	printf(*"span debug\n")
	printf(*"this:%p add:%p lim:%p\n",this,this.startaddr,this.limit)
	printf(*"page:%d state:%d alloc:%d\n",this.npages,this.state,this.allocCount)
	printf(*"sc:%d elemsize:%d freeindex:%d\n",this.sc,this.elemsize,this.freeindex)
	printf(*"nlemes:%d allocb:%p gcb:%p alloc:%p\n",this.nelems,this.allocBits,this.gcmarkBits,this.allocCache)
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
    if ( physPageSize > pageSize ) {
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
    sys_unused(start,released)
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
	bitIndex<i32>  = ctz64(aCache)
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
		bitIndex = ctz64(aCache)
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

Spanlist::isEmpty(){
	return this.first == Null
}
Spanlist::takeAll(other<Spanlist>){
	if other.isEmpty() == True {
		return True
	}

	for s<Span> = other.first; s != Null; s = s.next {
		s.list = this
	}

	if this.isEmpty() == True {
		this.first = other.first
		this.last = other.last
	} else {
		other.last.next = this.first
		this.first.prev = other.last
		this.first = other.first
	}

	other.first = Null
	other.last = Null
}

Span::nextFreeFast()
{
	theBit<i32> = ctz64(this.allocCache)
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
