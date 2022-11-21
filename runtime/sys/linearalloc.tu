use std
use os

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
		map(this.mapped,pEnd - this.mapped)
		this.mapped = pEnd
	}
	return p
}