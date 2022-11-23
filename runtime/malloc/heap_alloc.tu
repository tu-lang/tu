use std
use std.atomic
use os
use runtime.sys

Heap::sysAlloc(n<u64> , ssize<u64*>)
{
	size<u64> = 0
	n = sys.round(n, heapArenaBytes)

	v<u64*> = this.arena.alloc(n,heapArenaBytes)
	if v != null {
		size = n
		goto mapped
	}

	while this.arenaHints != null {
		hint<ArenaHint> = this.arenaHints
		p<u64> = hint.addr
		if hint.down {
			p -= n
		}
		if( p+n < p ){
			v = null
		} else if arenaIndex(p + n - 1) >= 1 << arenaBits {
			v = null
		} else {
			v = sys.reserve(p, n)
		}
		if( p == v ){
			if !hint.down {
				p += n
			}
			hint.addr = p
			size = n
			break
		}
		if v != null {
			sys.free(v, n)
		}
		this.arenaHints = hint.next
		this.arenaHintAlloc.free(hint)
	}

	if size == 0 {
		v<u64*> = 0
		size<u64> = n

		v = sys.reserveAligned(0.(i8),&size,heapArenaBytes)
		if( v == null ){
			*ssize = 0
			return 0.(i8)
		}
		hint<ArenaHint> = this.arenaHintAlloc.alloc()
		hint.addr = v
		hint.down = true
		hint.next = this.arenaHints
		this.arenaHints = hint

		hint = this.arenaHintAlloc.alloc()
		hint.addr = v + size
		hint.down = true
		hint.next = this.arenaHints
		this.arenaHints = hint
	}

	bad<i32> = 0
	p<u64> = v
	if( p+size < p ){
		bad = 1
		//"region exceeds u64 range"
	} else if( arenaIndex(p) >= 1<<arenaBits ){
		bad = 1
		//"base outside usable address space"
	} else if( arenaIndex(p+size - 1) >= 1<<arenaBits ){
		bad = 1
		//"end outside usable address space"
	}
	// if( bad != "" ){
	if bad {
		dief("memory reservation exceeds address space limit".(i8))
	}

	if v&(heapArenaBytes - 1) != 0  {
		dief("misrounded allocation in sysAlloc".(i8))
	}

	sys.map(v,size)

mapped: 
	for ri<u32> = arenaIndex(v); ri <= arenaIndex(v+size - 1); ri += 1  {
		l2<u64*> = this.arenas[arena_l1(ri)]
		if l2 == null {
			l2 = sys.fixalloc( 1 << arenaL2Bits * ptrSize)
			if l2 == null {
				dief("out of memory allocating heap arena map".(i8))
			}
			atomic.store64(&this.arenas[arena_l1(ri)],l2)
		}
		if l2[arena_l2(ri)] != null {
			dief("arena already initialized".(i8))
		}
		r<HeapArena> = 0
        r = sys.fixalloc(sizeof(HeapArena), ptrSize)
        if r == null {
            dief("out of memory allocating heap arena metadata".(i8))
        }
		//OPTIMIZE:
		atomic.store64(l2 + arena_l2(ri) * ptrSize, r)
	}

    *ssize = size
	return v
}

