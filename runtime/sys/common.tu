//FIXME: __thread  Coroutine* _g_;
use fmt
use std

STDOUT<i64> = 1
THREAD_STACK_SIZE<i64> = 32768
THREAD_TLS_SIZE<i64>   = 1024

// clone
SIGCHLD<i64>      		  = 0x11
CLONE_CHILD_CLEARTID<i64> = 0x00200000
CLONE_VM<i64>             = 0x100
CLONE_FS<i64>             = 0x200
CLONE_FILES<i64>          = 0x400
CLONE_SIGHAND<i64>        = 0x800
CLONE_SYSVSEM<i64>        = 0x40000
CLONE_THREAD<i64>         = 0x10000

func dief(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
	std.die(-1.(i8))
}

func outf(str<i8*>,arg1<i64>,arg2<i64>,arg3<i64>,arg4<i64>,arg5<i64>){
	fmt.vfprintf(STDOUT,str,arg1,arg2,arg3,arg4,arg5)
}