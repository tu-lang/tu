use fmt
use runtime
use os

CUR_CALLER<i32> = 3
func callerpc(){
	sinfo = stack(CUR_CALLER)
	if std.len(sinfo) >= 3 {
		return sinfo[2]
	}
	return "??:??"
}
func stack(level<i32>){
	bp<u64*> = runtime.get_bp()
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