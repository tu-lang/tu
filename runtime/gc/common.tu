use runtime.sys
use runtime.malloc
use std

Null<i64> = 0
True<i64> = 1
// buf list 
WorkbufSize<i64> = 2048
BufObjsize<i64>  = 253
addrBits<i64> 	 = 48
cntBits<i64>     = 19
BufAlloc<i64>    = 32768

enum {
	GcAlways,
	GcHeap
}
mem SpanCache {
	sys.MutexInter    lock
	malloc.Spanlist   free
	malloc.Spanlist   busy
}

mem MarkBits {
	u8*  u8p
	u8   mask
	u64 index
}
MarkBits::isMarked(){
	return (*this.u8p & this.mask) != 0
}
MarkBits::setMarked(){
	//GCTODO: 
	//atomic.Or8(this.u8p,this.mask)
}

mem Gc {
	i32 kind
	u32 n
	i64 now

	List full
	List empty
	i32  forced
	u64  marked
	u32  cycles
	SpanCache 		spans
	sys.Sema        startSema
	sys.MutexInter  worldSeam

	u64 gc_trigger 
	u64 heaplives
	u64 heapmarked
	i32 enablegc

	i64  markStartTime
}
enable_trace<i64> = 1

fn tracef(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	if enable_trace {
		fmt.vfprintf(std.STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	}
}
fn dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	if enable_trace {
		fmt.vfprintf(std.STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	}
	std.die(-1.(i8))
}

fn get_sp()
fn get_di()
fn get_si()
fn get_dx()
fn get_cx()
fn get_r8()
fn get_r9()
fn get_bp()
fn get_ax()
fn get_bx()