use fmt
use runtime.gc
use os
func stack(level<i32>){
	bp<u64*> = gc.get_bp()
	i<i32> = 0
	arr = []
	//stack backtrace 
	while i < level {
		pc<u64*> = bp + 8
		rip<u64> = *pc
		if rip == null break
		arr[] = findpc(rip)
		bp = *bp
		i += 1
	}
	return arr
}