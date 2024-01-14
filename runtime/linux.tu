use std
use std.atomic
use os
use runtime

gcBlackenEnabled<u32> = 0
ncpu<u32> = 0

allm<u64:10> = null

func sys_fixalloc(size<u64> , align<u64>)
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
		return sys_alloc(size)
	}
	mp<Core> = runtime.acquirem()

	persistent<Palloc> = null
	if mp != null && mp.p != 0 {
		persistent = &mp.p.pl
	} else {
		ga_lock.lock()
		persistent = &globalAlloc
	}
	persistent.off = round(persistent.off, align)
	if ( persistent.off + size > persistentChunkSize) || persistent.base == null {
		persistent.base = sys_alloc(persistentChunkSize)
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
	runtime.releasem(mp)
	if persistent == &globalAlloc {
		ga_lock.unlock()
	}
	return p
}

adviseUnused<u32> = 0x8 // _MADV_FREE
func sys_alloc(n<u64>)
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

func sys_unused(v<u64> , n<u64>)
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

func sys_used(v<u64>,n<u64>)
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
func sys_free(v<u64>,n<u64>)
{
	std.munmap(v, n)
}
func fault(v<u64>,n<u64>)
{
	std.mmap(v, n, _PROT_NONE, _MAP_ANON|_MAP_PRIVATE|_MAP_FIXED, -1.(i8), 0.(i8))
}
func sys_reserve(v<u64>,n<u64>)
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
	
	p = sys_reserve(v, size + align)
	if p == 0 {
        return 0.(i8)
    }
	if p & (align - 1) == 0 {
        *ssize = size + align
        return p
    }
    pAligned = round(p, align)
    sys_free(p,pAligned - p)
    end = pAligned + size
    endLen = (p + size + align) - end
    if endLen > 0 {
        sys_free(end,endLen)
    }
    return pAligned
}

func sys_map(v<u64>,n<u64>)
{
	p<u64> = std.mmap(v, n, _PROT_READ|_PROT_WRITE, _MAP_ANON|_MAP_FIXED|_MAP_PRIVATE, -1.(i8), 0.(i8))
	if p == _ENOMEM {
		dief("runtime: out of memory".(i8))
	}
	if p != v {
		dief("runtime: cannot map pages in arena address space".(i8))
	}
}

fn futexsleep(addr<u32*> , val<u32> , ns<i64>){
    if ns < 0 {
        futex(addr,FUTEX_WAIT,val,Null,Null,Null)
        return Null
    }
    ts<TimeSpec:> = null
    futex(addr,FUTEX_WAIT,val,&ts,Null,Null)
}
fn futexwakeup(addr<u32*> , cnt<u32>) {
    ret<i32> = futex(addr,FUTEX_WAKE,cnt,Null,Null,Null)
    if ret >= 0 {
        return Null
    }
    panic<i32*> = 0x1006
    *panic = 0x1006
}

func round(n<u64>,a<u64>)
{
    return (n + a - 1) &~ (a - 1)
}
func fastrand()
{
    g<Coroutine> = runtime.getg()
    mp<Core>  = g.m
    s1<u32> = 0
    s0<u32> = 0
    s1 = mp.fastrand[0]
    s0 = mp.fastrand[1]
    s1 ^= s1 << 17
    s1 = s1 ^ s0 ^ s1 >> 7 ^ s0 >> 16
    mp.fastrand[0] = s0
    mp.fastrand[1] = s1
    return s0 + s1
}
func ctz64(x<u64>)
{
    x &= 0 - x                      
    y<i32>  = x * deBruijn64 >> 58    
    i<i32>  = deBruijnIdx64[y]   
    z<i32>  = (x - 1) >> 57 & 64 
    return i + z
}

