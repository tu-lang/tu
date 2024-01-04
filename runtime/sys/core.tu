use runtime.malloc
use std

mem Mutex {
	i64 lock
	i64 state
}
Mutex::init(){}
Mutex::lock(){}
Mutex::unlock(){}

enum {
	CoreRun ,
	CoreStop ,
}

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
	u64			stk , stk_hi
	u64			tls , tls_hi	
	u64			cfn
	u32			state
}
Core::init(){
	//TODO: queue buf init
	this.mallocing = 0
	this.state = CoreStop
}
// impl by asm
func clone(cloneflags<u64> , newsp<u64> , tls<u64> , funcp<u64> , args<u64> , args2<u64>)

func corestart(c<Core>){
    //setcore(c)
    //gc.worldSeam.Lock()
    //c.local = alloccache() 
    //c.status = CoreRun
    //sched.addcore(c)
    //gc.worldSeam.Unlock()
	fc<u64*> = c.cfn
	fc()
    //stopm
    //schedule()
    //sched.rmcore(c)
}

func newcore(fc<u64>){
	c<Core> = new Core()
	c.cfn = fc
	c.stk = malloc.malloc(THREAD_STACK_SIZE,1.(i8) , 1.(i8))
    c.stk_hi = c.stk + THREAD_STACK_SIZE
    c.tls = malloc.malloc(THREAD_TLS_SIZE,1.(i8),1.(i8))
    c.tls_hi = c.tls + THREAD_TLS_SIZE


    cid<i32> = newosthread(corestart,c,c.stk_hi,c.tls_hi)

	if cid <= 0
        dief("pthread create faild %d".(i8),cid)
}

func newosthread(fc<u64> , arg<i64*> , stk<i64*>, tls<i64*>){
	cloneFlags<u32> = 
        SIGCHLD  | CLONE_CHILD_CLEARTID |
        CLONE_VM | CLONE_FS | 
		CLONE_FILES | CLONE_SIGHAND | 
		CLONE_SYSVSEM | CLONE_THREAD 
	newpid<i32> = clone(cloneFlags, stk ,tls,fc,arg,0.(i8))

	if newpid < 0 {
		outf("failed to create new OS thread ( errno=%d)\n".(i8),newpid)
		if newpid == 0 - _EAGAIN {
			outf("may need to increase max user processes (ulimit -u)\n".(i8))
		}
		dief("new os thread".(i8))
	}
    return newpid
}
