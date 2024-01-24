
use std

mem TimeSpec {
	i64 sec,nsec
}

func sleep(sec){
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	req.sec = *sec
	std.nanosleep(&req,&rem)
}
func usleep(mill){
	req<TimeSpec:> = null
	rem<TimeSpec:> = null
	req.nsec = *mill
	std.nanosleep(&req,&rem)
}
