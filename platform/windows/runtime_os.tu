# Windows OS memory + sync (parallel to linux.tu / darwin runtime_os).
# std_mmap thunks to VirtualAlloc; flags mostly ignored except addr/prot.

use std
use std.atomic
use os
use runtime

gcBlackenEnabled<u32> = 0
ncpu<u32> = 0

fn host_os() i32 {
	return 2
}

W_PROT_READWRITE<i64> = 0x3
W_MAP_ANON_PRIVATE<i64> = 0x22
W_MAP_ANON_PRIVATE_FIXED<i64> = 0x32

func sys_fixalloc(size<u64> , align<u64>)
{
	p<u64> = null
	maxBlock<u64> = 65536

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
	c<Core> = core()

	persistent<Palloc> = null
	if c != null  {
		persistent = &c.pl
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
	
	if persistent == &globalAlloc {
		ga_lock.unlock()
	}
	return p
}

adviseUnused<u32> = 0x8
func sys_alloc(n<u64>)
{
	p<u64> = std.mmap(0.(i8), n, W_PROT_READWRITE, W_MAP_ANON_PRIVATE, -1.(i8), 0.(i8))
	if p == _EACCES {
		dief("runtime: mmap: access denied".(i8))
	}
	if p == _EAGAIN {
		dief("runtime: mmap: too much locked memory".(i8))
	}
	return p
}

func sys_unused(v<u64> , n<u64>)
{
	if ( v & (physPageSize - 1) != 0 || n & (physPageSize - 1) != 0) {
		dief("unaligned sysUnused".(i8))
	}
	std.madvise(v, n, adviseUnused)
}

func sys_used(v<u64>,n<u64>)
{
}

func sys_free(v<u64>,n<u64>)
{
	std.munmap(v, n)
}
func fault(v<u64>,n<u64>)
{
	std.mmap(v, n, _PROT_NONE, W_MAP_ANON_PRIVATE_FIXED, -1.(i8), 0.(i8))
}
func sys_reserve(v<u64>,n<u64>)
{
	p<u64> = std.mmap(v, n, _PROT_NONE, W_MAP_ANON_PRIVATE, -1.(i8), 0.(i8))
	if p == 0 {
		return 0.(i8)
	}
	// Reject error-sized / non-user pointers (high bit set).
	if p & 0x8000000000000000 != 0 {
		return 0.(i8)
	}
	return p
}

// VirtualFree(MEM_RELEASE) only accepts the base of a whole reservation.
// Partial munmap (Linux/Darwin reserveAligned) is invalid on Windows.
func reserveAligned(v<u64> , ssize<u64*> , align<u64>)
{
	size<u64> = *ssize
	p<u64> = 0
	pAligned<u64> = 0
	retries<i32> = 0

	if v != 0 {
		p = sys_reserve(v, size)
		if p == v {
			return p
		}
		if p != 0 {
			sys_free(p, size)
		}
	}

	while retries < 100 {
		p = sys_reserve(0.(i8), size + align)
		if p == 0 {
			return 0.(i8)
		}
		if p & (align - 1) == 0 {
			*ssize = size + align
			return p
		}
		pAligned = round(p, align)
		sys_free(p, size + align)
		p = sys_reserve(pAligned, size)
		if p == pAligned {
			return p
		}
		if p != 0 {
			sys_free(p, size)
		}
		retries = retries + 1
	}
	return 0.(i8)
}

func sys_map(v<u64>,n<u64>)
{
	p<u64> = std.mmap(v, n, W_PROT_READWRITE, W_MAP_ANON_PRIVATE_FIXED, -1.(i8), 0.(i8))
	if p == _ENOMEM {
		dief("runtime: out of memory".(i8))
	}
	if p != v {
		dief("runtime: cannot map pages in arena address space".(i8))
	}
}

fn futexsleep(addr<u32*> , val<u32> , ns<i64>){
	if addr.(u64) % 4.(u64) != 0 {
		dief(*"runtime: futexsleep misaligned addr:%p", addr)
	}
    if ns < 0 {
        ret<i32> = futex(addr,FUTEX_WAIT_PRIVATE,val,Null,Null,Null)
    	if ret < 0 {
			if ret != 0 - _EAGAIN && ret != 0 - 4 {
				warn(*"[futexsleep] addr:%p cnt:%d flag:%d ret:%d\n",addr,val,FUTEX_WAIT_PRIVATE,ret)
			}
    	}
        return Null
    }
    ts<TimeSpec:> = null
    ts.init(ns)
    futex(addr,FUTEX_WAIT_PRIVATE,val,&ts,Null,Null)
    return Null
}
fn futexwakeup(addr<u32*> , cnt<u32>) {
	if addr.(u64) % 4.(u64) != 0 {
		dief(*"runtime: futexwakeup misaligned addr:%p", addr)
	}
    ret<i32> = futex(addr,FUTEX_WAKE_PRIVATE,cnt,Null,Null,Null)
    if ret >= 0 {
        return Null
    }
	warn(*"[futexwakeup] addr:%p cnt:%d flag:%d ret:%d\n",addr,cnt,FUTEX_WAKE_PRIVATE,ret)
    panic<i32*> = 0x1006
    *panic = 0x1006
}

func round(n<u64>,a<u64>)
{
    return (n + a - 1) &~ (a - 1)
}
func fastrand()
{
	c<Core> = core()
    s1<u32> = 0
    s0<u32> = 0
    s1 = c.fastrand[0]
    s0 = c.fastrand[1]
    s1 ^= s1 << 17
    s1 = s1 ^ s0 ^ s1 >> 7 ^ s0 >> 16
    c.fastrand[0] = s0
    c.fastrand[1] = s1
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

fn type_fixalloc_first(h<Heap> , s<Span>)

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
        callback<type_fixalloc_first> = this.first
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

fn segsegv_rip(ctxt<u64>) u64 {
	return 0.(u64)
}

fn segsegv_walkstack(){
}

// Parse GetCommandLineA / GetEnvironmentStringsA raw pointers into
// argc/argv/envp vectors and delegate to args_init (entry asm calls this).
// Command-line quoting follows the classic CRT rules: quotes toggle a
// quoted span, n backslashes before a quote emit n/2 (odd keeps a literal
// quote), backslashes elsewhere are literal.
fn win_args_init(cmdline<i8*>, envblk<i8*>) {
	if cmdline == null {
		args_init(0.(u64), null, null)
		return
	}
	n<i32> = std.strlen(cmdline)
	n64<u64> = n + 1
	buf<i8*> = malloc(n64, 1.(i8), 1.(i8))
	std.memcpy(buf, cmdline, n64)
	// Upper bound on argv entries: one per two chars, plus program + NULL.
	vecn<u64> = (n / 2 + 3) * 8
	vec<u64*> = malloc(vecn, 1.(i8), 1.(i8))
	argc<i32> = 0
	i<i32> = 0
	w<i32> = 0
	c<i8> = buf[i]
	// argv[0] program path: quotes group, no backslash rules.
	start<i32> = w
	if c == 34 {
		i += 1
		loop {
			c = buf[i]
			if c == 0 {
				break
			}
			if c == 34 {
				i += 1
				break
			}
			d0<i8*> = buf + w
			*d0 = c
			w += 1
			i += 1
		}
	} else {
		loop {
			c = buf[i]
			if c == 0 || c == 32 || c == 9 {
				break
			}
			d1<i8*> = buf + w
			*d1 = c
			w += 1
			i += 1
		}
	}
	t0<i8*> = buf + w
	*t0 = 0
	w += 1
	slot0<u64*> = vec
	tok0<u64> = buf + start
	*slot0 = tok0
	argc = 1
	// Remaining args with CRT backslash/quote rules.
	loop {
		loop {
			c = buf[i]
			if c != 32 && c != 9 {
				break
			}
			i += 1
		}
		if buf[i] == 0 {
			break
		}
		start = w
		inq<i32> = 0
		loop {
			c = buf[i]
			if c == 0 {
				break
			}
			if c == 92 {
				k<i32> = 0
				loop {
					if buf[i] != 92 {
						break
					}
					k += 1
					i += 1
				}
				h<i32> = k
				if buf[i] == 34 {
					h = k / 2
				}
				e<i32> = 0
				while e < h {
					d2<i8*> = buf + w
					*d2 = 92.(i8)
					w += 1
					e += 1
				}
				if buf[i] == 34 && (k % 2) == 1 {
					d3<i8*> = buf + w
					*d3 = 34.(i8)
					w += 1
					i += 1
				}
				continue
			}
			if c == 34 {
				if inq {
					inq = 0
				} else {
					inq = 1
				}
				i += 1
				continue
			}
			if inq == 0 && (c == 32 || c == 9) {
				break
			}
			d4<i8*> = buf + w
			*d4 = c
			w += 1
			i += 1
		}
		t1<i8*> = buf + w
		*t1 = 0
		w += 1
		slot1<u64*> = vec + argc * 8
		tok1<u64> = buf + start
		*slot1 = tok1
		argc += 1
	}
	endslot<u64*> = vec + argc * 8
	*endslot = 0
	// Environment block: NUL-separated entries, double NUL terminates.
	ecnt<i32> = 0
	j<i32> = 0
	if envblk != null {
		loop {
			if envblk[j] == 0 {
				break
			}
			ecnt += 1
			loop {
				if envblk[j] == 0 {
					break
				}
				j += 1
			}
			j += 1
		}
	}
	evn<u64> = (ecnt + 1) * 8
	evec<u64*> = malloc(evn, 1.(i8), 1.(i8))
	j = 0
	ei<i32> = 0
	if envblk != null {
		loop {
			if envblk[j] == 0 {
				break
			}
			eslot<u64*> = evec + ei * 8
			ep<u64> = envblk + j
			*eslot = ep
			ei += 1
			loop {
				if envblk[j] == 0 {
					break
				}
				j += 1
			}
			j += 1
		}
	}
	elast<u64*> = evec + ei * 8
	*elast = 0
	a64<u64> = argc
	args_init(a64, vec, evec)
}
