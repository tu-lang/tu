
use std
use runtime

mem TimeSpec {
	i64 sec,nsec
}
Einter<i32> = 4

export func sleep(sec){
	sv<runtime.Value> = sec
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	if sv != null {
		req.sec = sv.data
	}
	req.nsec = 0

	ret<i32> = std.nanosleep(&req,&rem)
}
export func usleep(mill){
	mv<runtime.Value> = mill
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	if mv != null {
		req.nsec = mv.data
	}
	std.nanosleep(&req,&rem)
}
