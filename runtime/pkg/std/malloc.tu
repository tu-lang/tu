use fmt
use os

BLOCK_FREE<u64> = 2880154539
BLOCK_USED<u64> = 3452816845
mem Heap_header {
	i32 		 type
	u64 		 size
	Heap_header* next
	Heap_header* prev
}

//global heap
ghead<Heap_header>
gtail<u64>
func free(ptr<u64*>)
{
	header<Heap_header> = ptr - sizeof(Heap_header)
	if header.type != BLOCK_USED return ZERO

	header.type	= BLOCK_FREE
	if header.prev != null && header.prev.type == BLOCK_FREE {
		//merge
		header.prev.next = header.next
		if header.next != null
			header.next.prev = header.prev

		header.prev.size += header.size

		header	= header.prev
	}

	if header.next != null && header.next.type == BLOCK_FREE {
		//merge
		header.size += header.next.size
		header.next = header.next.next
	}
}

func realloc(p<u64*>, nbytes<u64>){
	if p == null {
		if nbytes < 0 {
			fmt.vfprintf(STDOUT,*"realloc failed\n")
			return ZERO
		}
		return malloc(nbytes)
	}
	if nbytes < 0 {
		free(p)
		return ZERO
	}
	newp<u64> = malloc(nbytes)
	memcpy(newp,p,nbytes)
	free(p)
	return newp
}
//TODO: memory expansion
func malloc(size<u64>){
	header<Heap_header> = null
	if size == 0 {
		return ZERO
	}
	header	= ghead
	headersize<i64> = sizeof(Heap_header)
	while header != null	{
		if header.type == BLOCK_USED {
			header = header.next
			continue
		}
		if headp.size <= headersize {
			header.type = BLOCK_USED
		}
		
		if header.size > size + headersize * 2 {
			//split
			next<Heap_header> = header + size + headersize
			if next > gtail {
				fmt.vfprintf(STDOUT,*"out of memory %d %d\n",next,gtail)
				initmalloc()
				return malloc(size)
			}
			next.prev	= header
			next.next	= header.next
			next.type	= BLOCK_FREE
			next.size	= header.size - size + headersize
			header.next	= next
			header.size	= size + headersize
			header.type	= BLOCK_USED
			return header + headersize
		}
		header = header.next
	}

	fmt.vfprintf(STDOUT,*"alloc failed h:%d e:%d\n",header,gtail)
	initmalloc()
	return malloc(size)
}

func initmalloc()
{
	base<u64> = 0
	header<Heap_header> = null
	//32MB heap size
	heap_size<u64> = 33554432

	base	 = brk(ZERO)
	end<u64> = base + heap_size
	end		 = brk(end)
	if end == null {
		fmt.vfprintf(STDOUT,*"extend malloc failed\n")
		return ZERO
	}
	header	= base

	header.size	= heap_size
	header.type	= BLOCK_FREE
	header.next	= null
	header.prev	= null

	ghead = header
	gtail = end

	return Done
}
