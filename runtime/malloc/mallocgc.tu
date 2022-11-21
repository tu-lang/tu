use std
use os
use sys

func mallocgc(size<u64> , noscan<u8> , needzero<u8>)
{
	if( sys.gcphase != _GCoff){
	}

	assistG<sys.Coroutine> = null
	if( sys.gcBlackenEnabled != 0 )
	{
		assistG = getg()
		if( assistG.m.curg != null ){
			assistG = assistG.m.curg
		}
		assistG.gcAssistBytes -= size
	}

	mp<sys.Core> = acquirem()
	if( mp.mallocing != 0 ){ 
		os.die("malloc deadlock")
	}
	if( mp.gsignal == getg() ){
		os.die("malloc during signal")
	}
	mp.mallocing = 1
	shouldhelpgc<u8> = false
	dataSize<u64>  = size
	g<sys.Coroutine> = getg()
	c<Cache> = g.m.mcache
	x<u64*> = null
	if( size <= maxSmallSize ){ 
		if( noscan && size < maxTinySize ){
			off<u64> = c.tinyoffset
			if( size&7 == 0 ) {
				off = sys.round(off, 8)
			} else if( size&3 == 0 ){
				off = sys.round(off, 4)
			} else if( size&1 == 0 ){
				off = sys.round(off, 2)
			}
			if( off+size <= maxTinySize && c.tiny != 0 ){
				x = (c.tiny + off)
				c.tinyoffset = off + size
				c.local_tinyallocs += 1
				mp.mallocing = 0
				releasem(mp)
				return x
			}
			s<Span> = c.alloc[tinySpanClass]
			v<u64> = s.nextFreeFast()

			if( v == 0 ) {
				v = c.nextFree(tinySpanClass,&s,&shouldhelpgc)
			}
			x = v
			//clear 16 bits
			x[0] = 0
			x[1] = 0
			if( size < c.tinyoffset || c.tiny == 0 ){
				c.tiny = x
				c.tinyoffset = size
			}
			size = maxTinySize
		} else {
			sz<u8> = 0
			if( size <= smallSizeMax - 8 ){
				sz = size_to_class8[(size+smallSizeDiv - 1)/smallSizeDiv]
			} else {
				sz = size_to_class128[(size-smallSizeMax+largeSizeDiv - 1)/largeSizeDiv]
			}
			size = (class_to_size[sz])
			spc<u8> = makeSpanClass(sz, noscan)
			s<Span> = c.alloc[spc]
			v<u64> = s.nextFreeFast()
			if( v == 0 ){
				v = c.nextFree(spc,&s,&shouldhelpgc)
			}
			x = v
			if( needzero && s.needzero != 0 ){
				std.memset(v,0,size)
			}
		}
	} else {
		s<Span> = null
		shouldhelpgc = true
		s = largeAlloc(size,needzero,noscan)
		s.freeindex = 1
		s.allocCount = 1
		x = s.startaddr
		size = s.elemsize
	}

	scanSize<u64> = null

	if( !noscan ){
		scanSize = size
		c.local_scan += scanSize
	}

	if( sys.gcphase != _GCoff ){
	}

	mp.mallocing = 0 
	releasem(mp)

	if( assistG != null ){
	}

	if( shouldhelpgc ){
	}
	fmt.println(int(x))
	return x
}
