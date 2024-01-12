use std.atomic
use std

mem Stack {
	MutexInter  spineLock
	u64*        spine     
	u64         spineLen  
	u64         spineCap  
	u32     	index
}

mem GcSweepBlock {
	u64 spans[SweepBlockEntries]
}
 
Stack::push(p<u64>)
{
	cursor<u32> = atomic.xadd(&this.index, 1) - 1
	top<u32>    = cursor / SweepBlockEntries
	bottom<u32> = cursor % SweepBlockEntries
 
	 spineLen<u64> = atomic.load64(&this.spineLen)
	 block<GcSweepBlock> = null
 
retry:
	 if top < spineLen {
		spine<u64*>  = atomic.load64(&this.spine)
		blockp<u64*> = spine + ptrSize * top
		block = atomic.load64(blockp)
	 } else {
		 this.spineLock.lock()
		 spineLen = atomic.load64(&this.spineLen)
		 if top < spineLen  {
			this.spineLock.unlock()
			goto retry
		 }
		 if spineLen == this.spineCap {
			newCap<u64> = this.spineCap * 2
			if newCap == 0 {
				newCap = StackInitSpineCap
			}
			newSpine<u64*> = sys.fixalloc(newCap * ptrSize,64.(i8))
			if this.spineCap != 0 {
				std.memcpy(newSpine, this.spine, this.spineCap * ptrSize)
			}
			atomic.store64(&this.spine, newSpine)
			this.spineCap = newCap
		 }
 
		 block = sys.fixalloc(sizeof(GcSweepBlock),CacheLinePadSize)
		 blockp<u64*> = this.spine + ptrSize * top
		 atomic.store64(blockp, block)
		 atomic.store64(&this.spineLen, spineLen+1)
		 this.spineLock.unlock()
	 }
	 block.spans[bottom] = p
}
 
Stack::pop(){
	cursor<u32> = atomic.xadd(&this.index, -1.(i8))
	if cursor < 0 {
		atomic.xadd(&this.index, 1)
		return Null
	}
	top<u32> = cursor / SweepBlockEntries
	bottom<u32> = cursor % SweepBlockEntries
	blockp<u64*> = this.spine + ptrSize * top
	block<GcSweepBlock>  = *blockp
	s<u64> = block.spans[bottom]
	block.spans[bottom] = Null
	return s
}
