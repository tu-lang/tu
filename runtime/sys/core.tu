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

// impl by asm
func clone(cloneflags<u64> , newsp<u64> , tls<u64> , funcp<u64> , args<u64> , args2<u64>)

func newosthread(fc<u64> , arg<i64*> , stk<i64*>, tls<i64*>){
	cloneFlags<u32> = 
        SIGCHLD  | CLONE_CHILD_CLEARTID |
        CLONE_VM | CLONE_FS | 
		CLONE_FILES | CLONE_SIGHAND | 
		CLONE_SYSVSEM | CLONE_THREAD 
	newpid<i32> = clone(cloneFlags, stk ,tls,fc,arg,0)

	if newpid < 0 {
		outf("failed to create new OS thread ( errno=%d)\n".(i8),newpid)
		if newpid == 0 - _EAGAIN {
			outf("may need to increase max user processes (ulimit -u)\n".(i8))
		}
		dief("new os thread".(i8))
	}
    return newpid
}
