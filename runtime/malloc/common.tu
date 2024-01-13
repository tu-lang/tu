use fmt
use os
use std
use runtime.sys

gcBitsChunkBytes<u64>  = 65536
gcBitsHeaderBytes<u64> = 16
arenaBaseOffset<u64> =  140737488355328
heapArenaBytes<i64>  =  67108864

arenaL1Bits<i64> 	 =  0
arenaL2Bits<i64>	 =  22
arenaBits<i64>       =  22
arenaL1Shift<i64> 	 =  22
pagesPerArena<i64> 	 = 8192
heapArenaBitmapBytes<i64> =  2097152

True<i64> = 1
Flase<i64> = 0

mSpanDead<i64>  = 1
mSpanInUse<i64> = 2
mSpanManual<i64> = 3
mSpanFree<i64> =  4

numSpanClasses<i64>   = 134
tinySpanClass<i64> 	  = 5
_NumSizeClasses<i64>  = 67 
largeSizeDiv<i64> 	  = 128
smallSizeMax<i64> 	  = 1024
smallSizeDiv<i64> 	  = 8
_MaxSmallSize<i64>   =  32768
maxTinySize<i64> 	 =  16
maxSmallSize<i64>	 =  32768

wordsPerBitmapByte<i64> = 4
pageShift<i64>        = 13 
PageMask<i64>   = 8191 
pageSize<i64>   = 8192
ptrSize<i64>	= 8
u64Mask<u64>		 =  9223372036854775808

heapBitsShift<i64>		= 1
bitPointer<i64>			= 1
bitScan<i64>		    = 16
bitScanAll<i64>			= 240
bitPointerAll<i64>      = 15 

_GCoff<i64>  =  1
_GCmark<i64> =  2                  
_GCmarktermination<i64> =  3
ARRAY_SIZE<i64> =  8
STDOUT<i64> = 1

g_<sys.Coroutine>

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

mem Spanlist {
    Span* first
    Span* last
}

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

fn bool2int(x<u8>){return x}
fn sizeclass(sc<u8>){
    return sc >> 1
}
fn noscan(sc<u8>){
    return (sc&1) != 0
}
fn makeSpanClass(sc<u8>,noscan<u8>)
{
    return sc << 1 | noscan

}

heap_<Heap:> 
physPageSize<u64> = 0
m0<sys.Core:>
g0<sys.Coroutine:>
emptyspan<Span:>

fn acquirem(){return g_.m}
fn releasem(m<Core>){}
fn getg(){ return g_ }

fn debug(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
}

fn dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}

fn mallocinit()
{
	sys.ncpu = 4
	sys.physPageSize = 4096
	sys.gcphase = _GCoff
	sys.gcBlackenEnabled = false

	heap_.init()

	g_ = &g0
    g_.m = &m0
    g_.m.mallocing  = 0
    g_.m.mcache = allocmcache()
	m0.mid = 0
	m0.pid = 10
	//TODO:
	// heap_.allspans.init(ARRAY_SIZE,sizeof(Span))
	heap_.locks.init()
	c0<u64> = 0xc0
    for i<i32> = 0x7f; i >= 0; i -= 1 {
		p<u64> = 0
		p = i<<40 | (u64Mask & (c0<<32) )
		hint<ArenaHint> = heap_.arenaHintAlloc.alloc()
		hint.addr = p
		hint.next = heap_.arenaHints
		heap_.arenaHints = hint
	}

	sys.allm[0] = g_.m
	while(sys.gcphase != _GCoff){}

}

fn largeAlloc(size<u64>, needzero<u8> , noscan<u8>)
{
	if size + sys.pageSize < size {
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
		os.die("malloc size == 0")
	}
	if( sys.gcphase != _GCoff){}

	assistG<sys.Coroutine> = null
	if( sys.gcBlackenEnabled != 0 )
	{
		assistG = getg()
		if( assistG.m.curg != null ){
			assistG = assistG.m.curg
		}
		assistG.gcAssistBytes -= size
	}

	mp<sys.Core> = acquirem()
	if( mp.mallocing != 0 ){ 
		dief("malloc deadlock".(i8))
	}
	if( mp.gsignal == getg() ){
		dief("malloc during signal".(i8))
	}
	mp.mallocing = 1
	shouldhelpgc<u8> = false
	dataSize<u64>  = size
	g<sys.Coroutine> = getg()
	c<Cache> = g.m.mcache
	x<u64*> = null
	if( size <= maxSmallSize ){ 
		if( noscan && size < maxTinySize ){
			off<u64> = c.tinyoffset
			if( size&7 == 0 ) {
				off = sys.round(off, 8.(i8))
			} else if( size&3 == 0 ){
				off = sys.round(off, 4.(i8))
			} else if( size&1 == 0 ){
				off = sys.round(off, 2.(i8))
			}
			if( off+size <= maxTinySize && c.tiny != 0 ){
				x = (c.tiny + off)
				c.tinyoffset = off + size
				c.local_tinyallocs += 1
				mp.mallocing = 0
				releasem(mp)
				return x
			}
			s<Span> = c.alloc[tinySpanClass]
			v<u64> = s.nextFreeFast()

			if( v == 0 ) {
				v = c.nextFree(tinySpanClass,&s,&shouldhelpgc)
			}
			x = v
			//clear 16 bits
			x[0] = 0
			x[1] = 0
			if( size < c.tinyoffset || c.tiny == 0 ){
				c.tiny = x
				c.tinyoffset = size
			}
			size = maxTinySize
		} else {
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
				v = c.nextFree(spc,&s,&shouldhelpgc)
			}
			x = v
			if( needzero && s.needzero != 0 ){
				std.memset(v,0.(i8),size)
			}
		}
	} else {
		s<Span> = null
		shouldhelpgc = true
		s = largeAlloc(size,needzero,noscan)
		s.freeindex = 1
		s.allocCount = 1
		x = s.startaddr
		size = s.elemsize
	}

	scanSize<u64> = null

	if( !noscan ){
		scanSize = size
		c.local_scan += scanSize
	}

	if( sys.gcphase != _GCoff ){
	}

	mp.mallocing = 0 
	releasem(mp)

	if( assistG != null ){
	}

	if( shouldhelpgc ){
	}
	return x
}
