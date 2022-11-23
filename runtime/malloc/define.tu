use fmt
use os
use std

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
func acquirem(){return g_.m}
func releasem(m<Core>){}
func getg(){ return g_ }

func dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}
