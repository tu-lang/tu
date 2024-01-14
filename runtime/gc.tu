use fmt
use std
use runtime.sys
use runtime.malloc

// buf list 
WorkbufSize<i64> = 2048
BufObjsize<i64>  = 253
addrBits<i64> 	 = 48
cntBits<i64>     = 19
BufAlloc<i64>    = 32768
enable_runtimemalloc<i64> = 1
gc<Gc:> = null

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

fn gc_malloc(nbytes<u64>)
{
	if enable_runtimemalloc<i64> {
		return malloc.malloc(nbytes,0.(i8),1.(i8))
	}
	return std.malloc(nbytes)
}

//discard..
fn GC(){}
fn gc_mark(){}
fn gc_free(ptr<u64>){}
fn gc_init(){}
fn gc_realloc(p<u64*>, pbytes<u64> , nbytes<u64>){
	if !p {
        if nbytes < 0 {
			dief(*"[gc] realloc failed")
        }
        return gc_malloc(nbytes)
    }
    if nbytes < 0 {
        gc_free(p)
        return Null
    }
    newp<u64*> = gc_malloc(nbytes)
    std.memcpy(newp,p,pbytes)
    gc_free(p)
    return newp
}