use std
use std.atomic
use os
use runtime.malloc

func fixalloc(size<u64> , align<u64>)
{
	p<u64> = null
	maxBlock<u64> = 65536 // 64 << 10 

	if size == 0  {
		dief("persistentalloc: size == 0".(i8))
	}
	if align != 0  {
		if align & (align - 1) != 0 
			dief("persistentalloc: align is not a power of 2 %d".(i8),align)
		if align > pageSize 
			dief("persistentalloc: align is too large".(i8))
	} else {
		align = 8
	}

	if size >= maxBlock {
		return alloc(size)
	}
	mp<Core> = malloc.acquirem()

	persistent<Palloc> = null
	if mp != null && mp.p != 0 {
		persistent = &mp.p.pl
	} else {
		ga_lock.lock()
		persistent = &globalAlloc
	}
	persistent.off = round(persistent.off, align)
	if ( persistent.off + size > persistentChunkSize) || persistent.base == null {
		persistent.base = alloc(persistentChunkSize)
		if persistent.base == null {
			if persistent == &globalAlloc {
				ga_lock.unlock()
			}
			dief("runtime: cannot allocate memory".(i8))
		}
		loop {
			chunks<u64> = persistentChunks
			*persistent.base = chunks
			if atomic.cas64(&persistentChunks, chunks, persistent.base) == True {
				break
			}
		}
		persistent.off = ptrSize
	}
	p = persistent.base + persistent.off
	persistent.off += size
	malloc.releasem(mp)
	if persistent == &globalAlloc {
		ga_lock.unlock()
	}
	return p
}


adviseUnused<u32> = 0x8 // _MADV_FREE
func alloc(n<u64>)
{
	p<u64> = std.mmap(0.(i8), n, _PROT_READ|_PROT_WRITE, _MAP_ANON|_MAP_PRIVATE, -1.(i8), 0.(i8))
	if p == _EACCES {
		dief("runtime: mmap: access denied".(i8))
	}
	if p == _EAGAIN {
		dief("runtime: mmap: too much locked memory (check 'ulimit -l').".(i8))
	}
	return p
}

func unused(v<u64> , n<u64>)
{

	if HugePageSize != 0 {
		s<u64> 	  = HugePageSize
		head<u64> = 0
		tail<u64> = 0

		if (v % s) != 0 {
			head = v &~ (s - 1)
		}
		if (v + n) % s != 0 {
			tail = (v + n - 1) & ~(s - 1)
		}

		if head != 0 && head + HugePageSize == tail {
			std.madvise(head, 2 * HugePageSize, _MADV_NOHUGEPAGE)
		} else {
			if head != 0 
				std.madvise(head, HugePageSize, _MADV_NOHUGEPAGE)
			if tail != 0 && tail != head 
				std.madvise(tail, HugePageSize, _MADV_NOHUGEPAGE)
		}
	}

	if ( v & (physPageSize - 1) != 0 || n & (physPageSize - 1) != 0) {
		dief("unaligned sysUnused".(i8))
	}

	advise<u32> = adviseUnused
    p<i32> = std.madvise(v, n, advise)
    if advise == _MADV_FREE && p == 0 {
		atomic.store32(&adviseUnused, _MADV_DONTNEED)
		std.madvise(v, n, _MADV_DONTNEED)
	}
}
func used(v<u64>,n<u64>)
{
	if HugePageSize != 0 {
		s<u64> = HugePageSize
		beg<u64> = 0
		end<u64> = 0

		beg = (v + (s - 1)) &~ (s - 1)
		end = (v + n) &~ (s - 1)

		if beg < end {
			std.madvise(beg, end - beg, _MADV_HUGEPAGE)
		}
	}
}
func free(v<u64>,n<u64>)
{
	std.munmap(v, n)
}
func fault(v<u64>,n<u64>)
{
	std.mmap(v, n, _PROT_NONE, _MAP_ANON|_MAP_PRIVATE|_MAP_FIXED, -1.(i8), 0.(i8))
}
func reserve(v<u64>,n<u64>)
{
	p<u64> = std.mmap(v, n, _PROT_NONE, _MAP_ANON|_MAP_PRIVATE, -1.(i8), 0.(i8))
	if p == 0 {
		return 0.(i8)
	}
	return p
}

func reserveAligned(v<u64> , ssize<u64*> , align<u64>)
{

	size<u64> = 0
	end<u64>  = 0 
	p<u64>    = 0 
	pAligned<u64> = 0
	endLen<u64> = 0

	size = *ssize
	retries<i32> = 0
	
	p = reserve(v, size + align)
	if p == 0 {
        return 0.(i8)
    }
	if p & (align - 1) == 0 {
        *ssize = size + align
        return p
    }
    pAligned = round(p, align)
    free(p,pAligned - p)
    end = pAligned + size
    endLen = (p + size + align) - end
    if endLen > 0 {
        free(end,endLen)
    }
    return pAligned
}

func map(v<u64>,n<u64>)
{
	p<u64> = std.mmap(v, n, _PROT_READ|_PROT_WRITE, _MAP_ANON|_MAP_FIXED|_MAP_PRIVATE, -1.(i8), 0.(i8))
	if p == _ENOMEM {
		dief("runtime: out of memory".(i8))
	}
	if p != v {
		dief("runtime: cannot map pages in arena address space".(i8))
	}
}
