use runtime.malloc
use std

mem Mutex {
	i64 lock
	i64 state
}
Mutex::init(){}
Mutex::lock(){}
Mutex::unlock(){}

mem Core {
    u64  			pid
    u32     		mid
	Coroutine* 		g0
	malloc.Cache*	mcache
	Runner*	 		p
	Mutex 			locks
	Coroutine*	curg
	i32    		mallocing
	Coroutine*	gsignal
	u32	 		fastrand[2]
}
