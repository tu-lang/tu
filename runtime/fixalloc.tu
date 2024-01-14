use std
use os
use fmt

mem Mlink {
    Mlink* next
}

mem Fixalloc {
    u64     size

    u64     first
    u64*    arg

    Mlink*  list

    u64     chunk
    u32     nchunk

    u64     inuse
    u8      zero
}

mem Palloc {
    u64*   base
    u64    off
}

globalAlloc<Palloc:>   = null
ga_lock<MutexInter:>
persistentChunks<u64*> = 0

Fixalloc::init(size<u64>,first<u64*>,arg<u64*>){
    this.size   = size
    this.first  = first

    this.arg    = arg
    this.list   = null
    this.chunk  = 0
    this.nchunk = 0
    this.inuse  = 0
    this.zero   = 1
}
Fixalloc::free(p<Mlink>)
{
    this.inuse -= this.size
    p.next  = this.list
    this.list  = p
}

Fixalloc::alloc() 
{
    v<u64> = null
    if this.size == 0 {
        dief("runtime: use of  fixalloc before fixalloc init".(i8))
    }
    
    if this.list != null {
        v = this.list
        this.list = this.list.next
        this.inuse += this.size
        if this.zero  {
            std.memset(v,0.(i8),this.size)
        }
        return v
    }
    if this.nchunk < this.size  {
        this.chunk = sys_alloc(fixAllocChunk)
        this.nchunk = fixAllocChunk
    }
    
    v = this.chunk
    if this.first != null  {
        callback<u64> = this.first
        callback(this.arg, v)
    }
    this.chunk  =  this.chunk + this.size
    this.nchunk -= this.size
    this.inuse  += this.size
    return v
}

mem LinearAlloc { u64   next , mapped , end}

LinearAlloc::alloc(size<u64>,align<u64>)
{
	p<u64> = round(this.next, align)
	if  p + size > this.end {
		return 0.(i8)
	}
	this.next = p + size
    pEnd<u64> = round(this.next - 1, physPageSize)
    if pEnd > this.mapped {
		sys_map(this.mapped,pEnd - this.mapped)
		this.mapped = pEnd
	}
	return p
}