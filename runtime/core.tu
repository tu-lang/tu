use std
use runtime

// impl by asm
fn core()
fn setcore()
fn clone(cloneflags<u64> , newsp<u64> , tls<u64> , funcp<u64> , args<u64> , args2<u64>)

enum {
	CoreRun ,
	CoreStop ,
}

mem Core {
	Core*	link
	u64     stktop
    u64  	pid,cid
	Cache*	local
	i32 	locks,mallocing
	u32	 	fastrand[2]
	Queue	queue
	Palloc 	pl
	u32		status
	Note 	park
	i32  	helpmark,helpsweep
	u64*    cfn
	u64* 	stk,stk_hi
	u64* 	tls,tls_hi
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

Sched::addcore(c<Core>){  
	sched.lock.lock()
	c.cid = sched.cid
	sched.cid += 1
	sched.cores += 1

	c.fastrand[0] = 1437154666 * c.cid
	c.fastrand[1] = std.cputicks()

	if(sched.cid > 1000)
		dief(*"system thread is over 1000")
	dgc(*"new core:%d",c.cid)
	c.link = sched.allcores
	atomic.store64(&sched.allcores,c)
	sched.lock.unlock()
}
Sched::rmcore(c<Core>){  
	sched.lock.lock()
	if c == sched.allcores {
		sched.allcores = c.link
	}else{
		cc<Core> = sched.allcores
		pc<Core> = sched.allcores

		while cc != Null {
			if c == cc break
			pc = cc
			cc = cc.link 
		}
		if cc == Null dief(*"ever happen")
		pc.link = cc.link
	}
	atomic.xadd(&sched.cores,-1.(i8))
	sched.lock.unlock()
}

fn unlock_callback(lk<MutexInter>){
	lk.unlock()
}
fn park(unlockf<u64> , lk<u64>){
	if unlockf != null {
		ok<i32> = unlockf(lk)
	}
	schedule()
}

fn parkunlock(lk<MutexInter>){
	park(unlock_callback,lk)
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
		debug("failed to create new OS thread ( errno=%d)\n".(i8),newpid)
		if newpid == 0 - _EAGAIN {
			debug("may need to increase max user processes (ulimit -u)\n".(i8))
		}
		dief("new os thread".(i8))
	}
    return newpid
}

Core::init(){
    this.queue.init()
    this.mallocing  = 0
    this.status = CoreStop
    this.helpmark = 0
    this.helpsweep = 0
}

fn newcore2(fc<u64*>){
    c<Core> = new Core
    c.init()
    c.cfn = fc
    c.stk = malloc(THREAD_STACK_SIZE,True,True)
    c.stk_hi = c.stk + THREAD_STACK_SIZE
    c.tls = malloc(THREAD_TLS_SIZE,True,True)
    c.tls_hi = c.tls + THREAD_TLS_SIZE

    cid<i32> = newosthread(corestart,c,c.stk_hi,c.tls_hi)
	if cid <= 0
        dief(*"pthread create faild %d",cid)
}
fn corestart(c<Core>){
    setcore(c)
    c.pid = std.gettid()
    c.stktop = get_bp()
    gc.worldSeam.lock()
    c.local = allocmcache() 
    c.status = CoreRun
    sched.addcore(c)
    gc.worldSeam.unlock()

    startfn<u64> = c.cfn
    startfn()
    schedule()
    sched.rmcore(c)
    debug(*"thread exit done")
    return Null
}
fn stopworld(){
    c<Core> = core()
retry:
    c.park.Sleep()
    c.park.Clear()

	if c.helpmark {
        dgc(*"follwer start marking")
        gcmarkhelper()
		c.helpmark = 0
        dgc(*"follwer end marking")
		goto retry
	}
    if c.helpsweep {
        dgc(*"follwer start sweeping")
        gcsweephelper()
        c.helpsweep = 0
        dgc(*"follwer end   sweeping")
        goto retry
    }
}
fn gcstopworld(){
    c<Core> = core()
	if !sched.gcwaiting
        dief(*"gcstop not waiting for gc")
    sched.lock.lock()
	c.status = CoreStop
    sched.stopwait -= 1
	if sched.stopwait == 0{
        dgc(*"Wake Main GC . all thread stop allcores:%d",sched.cores)
        sched.stopnote.Wake()
    }
    sched.lock.unlock()

    stopworld()
}
fn schedule(){
top:
	if sched.gcwaiting {
        dgc(*"Found Need Gc")
		gcstopworld()
		goto top
	}
    if sched.debug != Null{
        debugfn<u64> = sched.debug
        debugfn()
    }
}
