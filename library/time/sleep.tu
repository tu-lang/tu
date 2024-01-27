
use std

mem TimeSpec {
	i64 sec,nsec
}
Einter<i32> = 4

func sleep(sec){
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	req.sec = *sec
	req.nsec = 0

	ret<i32> = std.nanosleep(&req,&rem)
}
func usleep(mill){
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	req.nsec = *mill
	std.nanosleep(&req,&rem)
}
