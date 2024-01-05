use std
use os
use std.atomic
use runtime.sys

gcBitsChunkBytes<u64>  = 65536
gcBitsHeaderBytes<u64> = 16

mem GcBitsArena {
    u64 		 free
    GcBitsArena* next
    u8 			 bits[65520]
}

mem GcBitsArenas {
    sys.Mutex    locks 
    GcBitsArena* free
    GcBitsArena* next
    GcBitsArena* current
    GcBitsArena* previous
}

gbArenas<GcBitsArenas:> = null

GcBitsArena::tryAlloc(u8s<u64>) 
{
	bitslen<u64> = gcBitsChunkBytes - gcBitsHeaderBytes
	if this == null || atomic.load64(&this.free) + u8s > bitslen {
		return 0.(i8)
	}
	end<u64> = atomic.xadd64(&this.free, u8s)
	if end > bitslen {
		return 0.(i8)
	}
	start<u64> = end - u8s
	return &this.bits[start]
}

GcBitsArenas::newArenaMayUnlock()
{
	result<GcBitsArena> = null
	if this.free == null {
		this.locks.unlock()
		result = sys.alloc(gcBitsChunkBytes)
		if result == null  {
			dief("runtime: cannot allocate memory".(i8))
		}
		this.locks.lock()
	} else {
		result = this.free
		this.free = this.free.next
		std.memset(result,0.(i8),gcBitsChunkBytes)
	}
	result.next = null
	result.free = 0
	return result
}
