//FIXME: __thread  Coroutine* _g_;
use fmt
use std

STDOUT<i64> = 1
func dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}
