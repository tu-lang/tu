use fmt
use runtime.gc
use os
func stack(level){
	fmt.println("debug stack backtrace:\n")
	bp<u64*> = gc.get_bp()
	i = 0
	//stack backtrace 
	while i < level {
		pc<u64*> = bp + 8
		rip<u64> = *pc
		if rip == null break
		fmt.print(i + ": ")
		os.shell("ta2l ./a.out " + int(rip))
		bp = *bp
		i += 1
	}
}