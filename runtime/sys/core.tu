use std
use runtime

enum {
	CoreRun ,
	CoreStop ,
}
//GCTODO:
mem Core {
	Core*			link
    u64  			pid
    u32     		mid
	i64				cid
	Coroutine* 		g0
	runtime.Cache*	mcache
	Runner*	 		p
	MutexInter		locks
	Coroutine*	curg
	i32    		mallocing
	Coroutine*	gsignal
	u32	 		fastrand[2]
	u64			stk , stk_hi
	u64			tls , tls_hi	
	u64			cfn
	u32			state
	runtime.Cache*	 local
	i32  helpmark
	i32  helpsweep
	Note park
	u32	 status
}
Core::init(){
	//TODO: queue buf init
	this.mallocing = 0
	this.state = CoreStop
}

mem Sched {
	MutexInter lock
	i32 	  cid
	i32 	  cores
	u32 	  gcwaiting
	i32		  stopwait
	Note	  stopnote
	i32		  stopmark
	Note	  allmarkdone
	i32		  stopsweep
	Note	  allsweepdone
	Core* 	  allcores
	u64 	  debug

}

fn unlock_callback(lk<MutexInter>){
	lk.unlock()
}
fn park(unlockf<u64> , lk<u64>){
	if unlockf != null {
		ok<i32> = unlockf(lk)
	}
	//GCTODO: 
	//schedule();
}

fn parkunlock(lk<MutexInter>){
	park(unlock_callback,lk)
}

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
	c.stk = runtime.malloc(THREAD_STACK_SIZE,1.(i8) , 1.(i8))
    c.stk_hi = c.stk + THREAD_STACK_SIZE
    c.tls = runtime.malloc(THREAD_TLS_SIZE,1.(i8),1.(i8))
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
// impl by asm
fn core()
fn setcore()
fn clone(cloneflags<u64> , newsp<u64> , tls<u64> , funcp<u64> , args<u64> , args2<u64>)