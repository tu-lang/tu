use runtime
use fmt
use std

// 内存分配器
// 分配策略:
// 1. 小内存就用当前的分配器 分配block
// 2. 超过256bytes就进行系统malloc调用
//
// 3. 下面有一个循环链表，多链表，加快内存分配
// ----------------------------------------------------------------
//    1-8                     8                       0
//	  9-16                   16                       1
//	 17-24                   24                       2
//	 25-32                   32                       3
//	 33-40                   40                       4
//	 41-48                   48                       5
//	 49-56                   56                       6
//	 57-64                   64                       7
//	 65-72                   72                       8
//	  ...                   ...                     ...
//	241-248                 248                      30
//	249-256                 256                      31
//
// 64 * 8 个内存空间
pools<u64*>
maxarenas<u32>
arenas<u64*>
unused_arena_objects<u64*>
usable_arenas<Arena>
narenas_currently_allocated<u64*>
spstart<u64*>

//macro
ALIGNMENT<i32> 		= 8
ALIGNMENT_SHIFT<i32> = 3
ALIGNMENT_MASK<i32>  = 7

SMALL_THRESHOLD<i32> = 256
SMALL_CLASSES<i32>  = 32
SYSTEM_PAGE_SIZE<i32> = 4096
SYSTEM_PAGE_SIZE_MASK<i32> = 4095

ARENA_SIZE<i32> = 262144 # 256 << 20 256kb
POOL_SIZE<i32>  = 4096
POOL_SIZE_MASK<i32> = 4095

BLOCK_MASK<i32> = 1234567
POOL_OVERHEAD<i32> = 48
DUMMY_SIZE_IDX<i32> = 65535
NOT_STACK<i8>     = 10
INITIAL_ARENA_OBJECTS<i8> = 16

True<i32> = 1
False<i32> = 0
Null<i32> = 0


mem Block {
	i32 flags
	i32 mask
	u64* addr
}

mem Pool {
	u8* 		ref # _padding,count
	Block*  	freeblock
	Pool* 		nextpool
	Pool* 		prevpool
	u32			arenaindex
	u32			szidx
	u32 		nextoffset
	u32			maxnextoffset
} 
mem Arena {
	u64 	address
	u8*		first_address
	u8* 	pool_address
	u32 	nfreepools
	u32 	ntotalpools

	Pool* 	freepools
	Arena*	nextarena
	Arena*	prevarena
}
func index2size(i<u32>){
	ret<u32> = i + 1
	ret <<= ALIGNMENT_SHIFT
	return ret
}

func numblocks(i<u64>){
	ret<u32> = POOL_SIZE - POOL_OVERHEAD	
	return ret / index2size(i)
}

func pool_addr(p<u64>){
	psm<u64> = POOL_SIZE_MASK
	ret<u64> = p & ~psm
	return ret
}
func pta(x<i32>){
	p<u64> = 2 * x * 8
	p 	  += pools
	p 	  -= 16
	return p
}
func in_heap(p<u64>,po<Pool>){
	areobj<Arena> = arenas + po.arenaindex * 8
	adr<u64> = areobj.address
	return po.arenaindex < maxarenas && p - adr < ARENA_SIZE && adr != null
}

FLAG_ALLOC<i8> = 1
FLAG_MARK<i8>  = 2
func flag_set(b<Block>,f<u64>){
	b.flags |= f
}
func flag_unset(b<Block>,f<u64>){
	b.flags &= ~f
}
func flag_test(b<Block>,f<u64>){
	return b.flags & f
}
func is_marked(p<u64>){
	l<i8> = flag_test(p,FLAG_ALLOC)
	r<i8> = flag_test(p,FLAG_MARK)
	if l && r return True
	else return False
}
func size_class(i<u32>){
	i -= 1
	return i >> ALIGNMENT_SHIFT
}
func getpool(i<i32>){
	p<u64*> = pools + i*8
	return *p
}
func getarena(i<i32>){
	return arenas + i * sizeof(Arena)
}
func assert(ret<i8>,str<i8*>){
    if ret return True
    die(str)
}
func die(msg<i8*>){
	if msg != null fmt.vfprintf(std.STDOUT,msg)
	code<i8> = -1
	std.die(code)
}