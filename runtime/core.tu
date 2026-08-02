use std
use runtime
use std.atomic

// impl by asm — see syscall/sys_runtime_amd64.s
// Args: flags, stack, child_tid*, fn, arg, tls (userspace settls; kernel tls unused).
fn core()
fn setcore()
fn clone(cloneflags<u64> , newsp<u64> , ctid<u64> , funcp<u64> , args<u64> , tls<u64>)

enum {
	CoreRun ,
	CoreStop ,
	CoreSyscall , // blocking syscall; STW treats as already stopped
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
	u32     clear_tid           // SETTID/CLEARTID futex word; non-zero while alive, 0 after exit
	i32     join_tracked        // legacy counter path; prefer core_join on clear_tid
	u64     syscall_sp          // SP saved at entersyscall for GC stack scan
	// Callee-saved register roots at soft-/blocking-syscall entry. Mark must
	// scan these: Tu may keep Task*/Future* live only in rbx/r12-r15 across
	// the futex/epoll call (stack scan from syscall_sp alone misses them).
	u64     syscall_bp
	u64     syscall_bx
	u64     syscall_r12
	u64     syscall_r13
	u64     syscall_r14
	u64     syscall_r15
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
	i32		  markwait              // cores expected to finish mark (excludes CoreSyscall)
	i32		  sweepwait             // cores expected to finish sweep

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
	// Serialize with Gc::start: GC walks allcores without sched.lock while
	// holding worldSeam (stopSTW / mark*). Unlink under the same seam so a
	// concurrent walker cannot follow a freed link (SEGV on newcore exit).
	// NOTE: do not adjust stopwait here — a naive Wake races with gcstopworld
	// and can false-wake STW or double-Wake. Exiting cores must join via
	// schedule()/gcstopworld first; tests should core_join workers.
	gc.worldSeam.lock()
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
	dec_cores<u32> = 4294967295
	atomic.xadd(&sched.cores, dec_cores)
	sched.lock.unlock()
	gc.worldSeam.unlock()
}

// Join counter for OS threads that opt in via core_join_inc (legacy).
// Prefer core_join(core_bits) on clear_tid for true OS-thread join.
CORE_JOIN_CNT<i32> = 0

fn core_join_reset() {
	CORE_JOIN_CNT = 0
}

fn core_join_inc() {
	c<Core> = core()
	// Do not compare mem to null — unreliable; worker_entry always has a Core.
	c.join_tracked = 1
	atomic.xadd(&CORE_JOIN_CNT, 1.(u32))
}

fn core_join_count() i32 {
	return CORE_JOIN_CNT
}

// Block until the OS thread for this Core has exited (CLEARTID zeros clear_tid).
// clear_tid is seeded non-zero before clone so a join racing SETTID never
// mistakes "not started yet" for "already exited".
fn core_join(core_bits<u64>) {
	if core_bits == 0 {
		return
	}
	c<Core> = core_bits.(Core)
	addr<u32*> = &c.clear_tid
	loop {
		v<u32> = atomic.load(addr)
		if v == 0 {
			return
		}
		// Kernel CLEARTID wakes with FUTEX_WAKE (not PRIVATE); match that op.
		futex(addr, FUTEX_WAIT, v, Null, Null, Null)
	}
}

fn type_unlock_callback(lk<MutexInter>)
fn unlock_callback(lk<MutexInter>){
	lk.unlock()
}
fn park(unlockf<type_unlock_callback> , lk<u64>){
	if unlockf != null {
		ok<i32> = unlockf(lk)
	}
	schedule()
}

fn parkunlock(lk<MutexInter>){
	park(unlock_callback.(i64),lk)
}

// Spawn an OS thread running fc; returns Core* bits for core_join.
// Callers that never join may ignore the return (fire-and-forget).
func newcore(fc<u64>) u64 {
	c<Core> = new Core()
    c.init()
	c.cfn = fc
	// Non-zero before clone: core_join must not see 0 until CLEARTID on exit.
	// SETTID overwrites with the real tid; CLEARTID zeros on thread exit.
	c.clear_tid = 0xFFFFFFFF
	c.stk = malloc(THREAD_STACK_SIZE,1.(i8) , 1.(i8))
    c.stk_hi = c.stk + THREAD_STACK_SIZE
    c.tls = malloc(THREAD_TLS_SIZE,1.(i8),1.(i8))
    c.tls_hi = c.tls + THREAD_TLS_SIZE

    cid<i32> = newosthread(corestart.(u64),c,c.stk_hi,c.tls_hi,&c.clear_tid)

	if cid <= 0
        dief("pthread create faild %d".(i8),cid)
	return c.(u64)
}

func newosthread(fc<u64> , arg<i64*> , stk<i64*>, tls<i64*>, ctid<u32*>){
	cloneFlags<u32> = 
        SIGCHLD  | CLONE_CHILD_SETTID | CLONE_CHILD_CLEARTID |
        CLONE_VM | CLONE_FS | 
		CLONE_FILES | CLONE_SIGHAND | 
		CLONE_SYSVSEM | CLONE_THREAD 
	newpid<i32> = clone(cloneFlags, stk ,ctid.(u64),fc,arg,tls.(u64))

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
    this.join_tracked = 0
    this.syscall_sp = 0
    this.syscall_bp = 0
    this.syscall_bx = 0
    this.syscall_r12 = 0
    this.syscall_r13 = 0
    this.syscall_r14 = 0
    this.syscall_r15 = 0
    // Seeded again in newcore before clone; 0 here only for zeroed Core layout.
    this.clear_tid = 0
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

    startfn<type_core_start> = c.cfn
    startfn()
    schedule()
    sched.rmcore(c)
    // After rmcore: safe for Runtime teardown. Only cores that opted in
    // via core_join_inc decrement CORE_JOIN_CNT.
    if c.join_tracked == 1 {
        c.join_tracked = 0
        // Explicit u32 all-bits: -1.(i8) zero-extends wrong; a-b in arg may miscompile.
        dec<u32> = 4294967295
        atomic.xadd(&CORE_JOIN_CNT, dec)
    }
    debug(*"thread exit done")
    return Null
}
fn stopworld(){
    c<Core> = core()
retry:
	// Help before sleeping so a Wake that raced ahead of Sleep is not lost
	// after Clear; also bail out once STW is finished.
	if c.helpmark != 0 {
        dgc(*"follwer start marking")
        gcmarkhelper()
		c.helpmark = 0
        dgc(*"follwer end marking")
		goto retry
	}
    if c.helpsweep != 0 {
        dgc(*"follwer start sweeping")
        gcsweephelper()
        c.helpsweep = 0
        dgc(*"follwer end   sweeping")
        goto retry
    }
	if sched.gcwaiting == 0 {
		return
	}
	c.park.Sleep()
    c.park.Clear()
	// startSTW sets CoreStop → CoreRun then Wake. If we are CoreRun, a new
	// GC round may already be starting — return so schedule() → gcstopworld
	// can re-register as CoreStop. CoreSyscall cores are not woken here.
	if c.status == CoreRun {
		return
	}
	goto retry
}
fn gcstopworld(){
    c<Core> = core()
    // May lose the race with STW finishing while we waited on sched.lock as
    // CoreSyscall (mutex soft-syscall). No-op instead of dief.
	if !sched.gcwaiting {
        return
    }
    sched.lock.lock()
    if !sched.gcwaiting {
        sched.lock.unlock()
        return
    }
	c.status = CoreStop
    // stopSTW may already have finished its wait (we were CoreSyscall); do
    // not underflow stopwait.
    if sched.stopwait > 0 {
        sched.stopwait -= 1
        if sched.stopwait == 0 {
            dgc(*"Wake Main GC . all thread stop allcores:%d",sched.cores)
            sched.stopnote.Wake()
        }
    }
    sched.lock.unlock()

    stopworld()
}
fn schedule(){
top:
	if sched.gcwaiting {
        dgc(*"Found Need Gc\n")
		gcstopworld()
		goto top
	}
    if sched.debug != Null{
        debugfn<type_sched_debug> = sched.debug
        debugfn()
    }
}

// Snapshot SP + callee-saved regs for GC while this core is CoreSyscall.
fn publish_syscall_roots(c<Core>) {
	c.syscall_sp = get_sp()
	c.syscall_bp = get_bp()
	c.syscall_bx = get_bx()
	c.syscall_r12 = get_r12()
	c.syscall_r13 = get_r13()
	c.syscall_r14 = get_r14()
	c.syscall_r15 = get_r15()
}

fn clear_syscall_roots(c<Core>) {
	c.syscall_sp = 0
	c.syscall_bp = 0
	c.syscall_bx = 0
	c.syscall_r12 = 0
	c.syscall_r13 = 0
	c.syscall_r14 = 0
	c.syscall_r15 = 0
}

// Mark this core as outside the mutator before a blocking syscall (epoll,
// nanosleep, …). stopSTW will not wait on CoreSyscall cores, but mark still
// scans syscall_sp..stktop and saved callee-saved regs. Must not hold
// runtime locks or be mallocing.
fn entersyscall() {
	c<Core> = core()
	if c == null {
		return
	}
	if c.locks != 0 || c.mallocing != 0 {
		return
	}
	if c.status != CoreRun {
		return
	}
	sched.lock.lock()
	if sched.gcwaiting != 0 {
		// STW already running — join it before the syscall instead.
		sched.lock.unlock()
		schedule()
		return
	}
	publish_syscall_roots(c)
	c.status = CoreSyscall
	sched.lock.unlock()
}

// Soft-syscall for MutexInter futex wait (c.locks > 0).
// Does not take sched.lock — the waited mutex may be sched.lock itself.
// Publishes CoreSyscall first, then Kick stopnote so stopSTW re-counts.
// Returns 1 if status flipped (caller must exitsyscall after the futex).
fn entersyscall_mutexblock() i32 {
	c<Core> = core()
	if c == null {
		return 0
	}
	if c.status != CoreRun {
		return 0
	}
	// Mid-malloc stacks are not safe to leave as CoreSyscall for mark.
	if c.mallocing != 0 {
		return 0
	}
	publish_syscall_roots(c)
	c.status = CoreSyscall
	if sched.gcwaiting != 0 {
		sched.stopnote.Wake()
	}
	return 1
}

// Re-enter the mutator after a blocking syscall. startSTW leaves CoreSyscall
// cores alone; we restore CoreRun when gcwaiting is clear. If STW/mark is
// still running, become CoreStop and park until startSTW wakes us.
fn exitsyscall() {
	c<Core> = core()
	if c == null {
		return
	}
	loop {
		sched.lock.lock()
		if c.status == CoreRun {
			clear_syscall_roots(c)
			sched.lock.unlock()
			return
		}
		if sched.gcwaiting == 0 {
			c.status = CoreRun
			clear_syscall_roots(c)
			sched.lock.unlock()
			return
		}
		// STW/mark in progress: join as CoreStop so markscan pass 2 sees us.
		c.status = CoreStop
		clear_syscall_roots(c)
		sched.lock.unlock()
		stopworld()
	}
}
