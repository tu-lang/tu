
use fmt
use os
use string

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
heap_<Heap:> 
physPageSize<u64> = 0
m0<sys.Core:>
g0<sys.Coroutine:>
emptyspan<Span:>


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

fn acquirem(){return g_.m}
fn releasem(m<Core>){}
fn getg(){ return g_ }



fn hash_key(data<u8*>,len<u64>){
    i<i64>   = 0
    key<i64> = 0
    for(i<u64> = 0 ; i < len ; i += 1){
        temp_key<u32> = key
        temp_data<u8*> = data + i
        key = temp_key * 31 + *temp_data
    }
    return key
}

fn get_hash_key(key<Value>){
    if  key.type == Bool || key.type == Int {
		return key.data
	}
    str<string.Str> = key.data
	if  key.type == String {
        return str.hash64()
		// return hash_key(str,str.len())
	}
    os.dief("[hash_key] unsupport type:%s" , type_string(key))
}
fn assert(ret<i8>,str){
    if ret return True
    os.die(str)
}

//implement by asm
fn callerpc()
fn nextpc(){
	return callerpc()
}

fn debug(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
}

fn dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(std.STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}

enable_trace<i64> = 1
fn tracef(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	if enable_trace {
		fmt.vfprintf(std.STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	}
}

enable_debug_gc<i64> = 1
fn dgc(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	if enable_debug_gc {
		fmt.vfprintf(std.STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	}
}