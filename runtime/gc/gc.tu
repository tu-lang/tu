use runtime
use fmt
use std

enable_runtimemalloc<i64> = 1
GC<Gc:> = null

fn gc_malloc(nbytes<u64>)
{
	if enable_runtimemalloc<i64> {
		return malloc.malloc(nbytes,0.(i8),1.(i8))
	}
	return std.malloc(nbytes)
}

//discard..
fn gc(){}
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