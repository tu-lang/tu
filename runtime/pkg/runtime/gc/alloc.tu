
hugmem<u64*>
use runtime
use fmt
use std

func newarena(){
	arenaobj<Arena> = null
	excess<u32> = null
	if unused_arena_objects == null {
		i<u32> = 0
		numarenas<u32> = 0
		nbytes<u64> = 0

		//double expand		
		if maxarenas numarenas = maxarenas << 1
		else numarenas = INITIAL_ARENA_OBJECTS

		if  numarenas <= maxarenas 
			return Null	

		nbytes = numarenas * sizeof(Arena)

		arenaobj = std.realloc(arenas, nbytes)
		if  arenaobj == Null return Null
		arenas = arenaobj
		assert(usable_arenas == null,*"alloc:31")	
		assert(unused_arena_objects == null,*"alloc:33")

		for (i = maxarenas ; i < numarenas ; i += 1) 
		{
			areobj<Arena> = arenas + i * sizeof(Arena)
			areobj.address = 0
			if i < numarenas - 1 {
				ii<i32> = i + 1
				areobj.nextarena = arenas + ii * sizeof(Arena)
			} else {
				areobj.nextarena = Null
			}
		}
		unused_arena_objects = arenas + maxarenas * sizeof(Arena)
		maxarenas = numarenas
	}
	if unused_arena_objects == Null {
		die(*"unused_arena_objects should not be null")
	}
	arenaobj = unused_arena_objects
	unused_arena_objects = arenaobj.nextarena
	assert(areobj.address == 0,*"54")

	arenaobj.address = std.malloc(ARENA_SIZE)
	if  arenaobj.address == 0 {
		arenaobj.nextarena = unused_arena_objects
		unused_arena_objects = arenaobj
		return Null
	}

	narenas_currently_allocated += 1

	arenaobj.freepools = Null
	arenaobj.pool_address = arenaobj.address
	arenaobj.nfreepools = ARENA_SIZE / POOL_SIZE
	if POOL_SIZE * arenaobj.nfreepools != ARENA_SIZE {
		die(*"should be arena_size")
	}
	excess = arenaobj.address & POOL_SIZE_MASK
	if  excess != 0 {
		arenaobj.nfreepools -= 1
		arenaobj.pool_address += POOL_SIZE - excess
	}
	arenaobj.first_address = arenaobj.pool_address

	arenaobj.ntotalpools = arenaobj.nfreepools

	return arenaobj
}

func malloc(nbytes<u64>)
{
	//gc alloc is is unstable right now
	//return std.malloc(nbytes)
	bp<Block>  = null
	po<Pool>   = null
	next<Pool> = null
	size<u32>  = null

	if nbytes > runtime.I32_MAX {
		return Null
	}
	if nbytes - 1  < SMALL_THRESHOLD  {
		size = size_class(nbytes)
		po = getpool(size + size)
		if po != po.nextpool {
			# refcount ++
			po.ref += 1

			bp = po.freeblock
			if bp == null {
				next = po.nextpool
				po = po.prevpool
				next.prevpool = po
				po.nextpool = next
				
				goto expend_pool
			}
			if bp == null die(*"bp == null")

			po.freeblock = bp.addr
			if po.freeblock != null 
				return bp

			if po.nextoffset <= po.maxnextoffset {
				po.freeblock = po + po.nextoffset

				po.nextoffset += index2size(size)
				po.freeblock.addr = null
				return bp
			}
			gc()
			return bp
		}
expend_pool:
		if usable_arenas == null {
			usable_arenas = newarena()
			if usable_arenas == null {
				goto redirect
			}
			usable_arenas.nextarena = null
			usable_arenas.prevarena = null
		}
		assert(usable_arenas.address != null,*"136")

		po = usable_arenas.freepools
		if po != null {
			usable_arenas.freepools = po.nextpool
			usable_arenas.nfreepools -= 1
			if usable_arenas.nfreepools == 0 {
				if usable_arenas.freepools != null die(*"usable_arenas.freepools == null")
				if usable_arenas.nextarena != null && usable_arenas.nextarena.prevarena != usable_arenas {
					die(*"usable_arenas.nextarena == null,prevarena == usable_arenas")
				}
				usable_arenas = usable_arenas.nextarena
				if usable_arenas != null {
					usable_arenas.prevarena = null
					assert(usable_arenas.address != null,*"152")
				}
			}else {
				assert(usable_arenas.freepools != null || usable_arenas.pool_address <= usable_arenas.address + ARENA_SIZE - POOL_SIZE ,*"153")
			}
		init_pool:
			next = getpool(size + size)
			po.nextpool = next
			po.prevpool = next
			next.nextpool = po
			next.prevpool = po
			po.ref = 1
			if po.szidx == size {

				bp = po.freeblock
				po.freeblock = bp.addr
				return bp
			}
			po.szidx = size
			size = index2size(size)
			bp = po + POOL_OVERHEAD
			po.nextoffset = POOL_OVERHEAD + size << 1
			po.maxnextoffset = POOL_SIZE - size
			po.freeblock = bp + size
			po.freeblock.addr = null
			return bp
		}
		if usable_arenas.nfreepools <= 0 {
			die(*"usable_arenas.nfreepools <= 0")
		}
		if usable_arenas.freepools != null {
			die(*"usable_arenas.freepools == null")
		}
		po = usable_arenas.pool_address
		if po <= usable_arenas.address + ARENA_SIZE - POOL_SIZE {
		}else {
			die(*"po <= usable_arenas.address + ARENA_SIZE - POOL_ADDR")
		}
							   
		po.arenaindex = usable_arenas - arenas

		if getarena(po.arenaindex) != usable_arenas {
			die(*"getarena != usable_arenas")
		}	
		po.szidx = DUMMY_SIZE_IDX
		usable_arenas.pool_address += POOL_SIZE
		usable_arenas.nfreepools -= 1

		if usable_arenas.nfreepools == 0 {
			assert(usable_arenas == null)
			assert(usable_arenas.nextarena.prevarena == usable_arenas)
			usable_arenas = usable_arenas.nextarena
			if usable_arenas != null {
				usable_arenas.prevarena = null
				assert(usable_arenas.address != null,*"213")
			}
		}
		goto init_pool
	}

redirect:
	if nbytes == 0
		nbytes = 1
	ret<Block> = std.malloc(nbytes)
	push(hugmem,&ret.addr,nbytes)
	return ret
}
func free(p<Block>)
{
	//gc is unstable right now
	return p
	po<Pool> = null
	lastfree<Block> = null
	next<Pool> = null
	prev<Pool> = null
	size<u32> = null

	if p == null	
		return Null
	po = pool_addr(p)
	if in_heap(p,po)  == True {

		 if po.ref <= 0 {
			 return True
		 }
		 if po.ref <= 0 {
			 die(*"po.ref <= 0")
		 }
		std.memset(p,runtime.Null,index2size(po.szidx))
		lastfree = po.freeblock
		p.addr = lastfree
		po.freeblock = p
		if lastfree != null{
			ao<Arena> = null
			nf<u32>   = null
			po.ref -= 1
			if po.ref != 0 {
				return True
			}
			next = po.nextpool
			prev = po.prevpool
			next.prevpool = prev
			prev.nextpool = next
			ao = getarena(po.arenaindex)
			po.nextpool = ao.freepools
			ao.freepools = po
			ao.nfreepools += 1
			nf = ao.nfreepools
			if ao.nextarena == null  return True 
			if nf <= ao.nextarena.nfreepools return True

			if ao.prevarena != null {
				if ao.prevarena.nextarena != ao {
					#FIXME: miss " lead dead while
					die(*"ao.prevarena.nextarena != ao")
				}	
				ao.prevarena.nextarena = ao.nextarena
			}else {
				if usable_arenas != ao {
					die(*"281: usable_arenas != ao")
				}
				usable_arenas = ao.nextarena
			}
			ao.nextarena.prevarena = ao.prevarena

			while ao.nextarena != null &&
					nf > ao.nextarena.nfreepools {
				ao.prevarena = ao.nextarena
				ao.nextarena = ao.nextarena.nextarena
			}

			assert(ao.nextarena == null ||
				ao.prevarena == ao.nextarena.prevarena,*"293")
			assert(ao.prevarena.nextarena == ao.nextarena,*"295")

			ao.prevarena.nextarena = ao
			if ao.nextarena != null
				ao.nextarena.prevarena = ao

			assert(ao.nextarena == null ||
				  nf <= ao.nextarena.nfreepools,*"302")
			assert(ao.prevarena == null ||
				  nf > ao.prevarena.nfreepools,*"303")
			assert(ao.nextarena == null ||
				ao.nextarena.prevarena == ao,*"306")
			assert((usable_arenas == ao &&
				ao.prevarena == null) ||
				ao.prevarena.nextarena == ao,*"309")

			return True
		}
		po.ref -= 1
		assert(po.ref > 0,*"314")	
		size = po.szidx
		next = getpool(size + size)
		prev = next.prevpool
		po.nextpool = next
		po.prevpool = prev
		next.prevpool = po
		prev.nextpool = po
		return True
	}

	del(hugmem,&p.addr)
	std.free(p)
}

func gc_malloc(nbytes<u64>)
{
	// return malloc(nbytes)
	return std.malloc(nbytes)
	hdr<Block> = malloc(nbytes + 8)
	std.memset(hdr,Null,nbytes+8)
	hdr.mask = BLOCK_MASK
	flag_set(hdr,FLAG_ALLOC)
	return &hdr.addr

}

func gc_init(){
	poolss<u64> = 512
	pools = std.malloc(poolss)
	spstart = get_bp()
	//init hug mem
	hugmem = std.malloc(sizeof(List))
	for (i<i32> = 0 ; i < 32 ; i += 1) {
		p<u64*> = pools + 2 * i * 8
		*p = pta(i)
		p += 8
		*p = pta(i)
	}
}
func gc_realloc(p<u64*>, nbytes<u64>){
	if !p {
        if nbytes < 0 {
			die(*"[gc] realloc failed")
        }
        return gc_malloc(nbytes)
    }
    if nbytes < 0 {
        gc_free(p)
        return Null
    }
    newp<u64*> = gc_malloc(nbytes)
    std.memcpy(newp,p,nbytes)
    gc_free(p)
    return newp
}
func gc_free(p<u64*>){
	free(p - 8)
}

