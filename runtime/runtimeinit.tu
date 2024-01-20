
use os
use std
use string
use fmt
use runtime
use runtime.debug

# start at core space init
ori_envp<u64*>
ori_argc<u64>
ori_argv<u64>
ori_envs<u64>
ori_execout<u64*>

self_path<i8*>

ErrorCode<i32> = -1

fn gcinit(){
	heap_.sweepdone = 1
	gc.heapmarked = heapmin / 2
	gc.setpercent(100.(i8))
	gc.startSema.sema = 1
	worldsema.sema = 1

	gc.enablegc = true
}
fn mallocinit()
{
	//TODOGC: sysconf
	ncpu = 4
	physPageSize = 4096
	gcphase = _GCoff
	gcBlackenEnabled = false

	settls(&coretls)
	setcore(&core0)
    core0.stktop = get_bp()
    core0.pid = std.gettid()

	heap_.init()

	g_ = &g0
    g_.m = &m0
    g_.m.mallocing  = 0
    g_.m.mcache = allocmcache()
	core0.local = allocmcache()
	m0.mid = 0
	m0.pid = 10

	heap_.allspans.init(ARRAY_SIZE,PointerSize)
	heap_.allarenas.init(ARRAY_SIZE,PointerSize)
	heap_.sweeparenas.init(ARRAY_SIZE,PointerSize)

	heap_.lock.init()
	c0<u64> = 0xc0
    for i<i32> = 0x7f; i >= 0; i -= 1 {
		p<u64> = 0
		p = i<<40 | (u64Mask & (c0<<32) )
		hint<ArenaHint> = heap_.arenaHintAlloc.alloc()
		hint.addr = p
		hint.next = heap_.arenaHints
		heap_.arenaHints = hint
	}

	allm[0] = g_.m
	while(gcphase != _GCoff){}

}

fn args_init(argc<u64>, argv<u64*>){
	//save exec out file
	ori_execout = argv - 8
	ori_execout = *ori_execout
	//start parse env info
	envp<u64*> = argv + argc * PointerSize
	c = int(argc)
	c -= 1
	ori_envp = envp # save env
	//save args
	arr = []
	while argc > 0 {
		if *argv == null {
			break
		}
		str<Value> = new Value
		str.type = String
		str.data = string.newstring(*argv)
		arr_pushone(str,arr)
		argv += PointerSize
		argc -= 1
	}
	ori_argc = c
	ori_argv = arr
	//save env
	envs = []
	while *envp != null {
		str1<Value> = new Value
		str1.type = String
		str1.data = string.newstring(*envp)
		arr_pushone(str1,envs)
		envp += PointerSize
	}
	ori_envs = envs
	//init current executetable path
	self_path =  std.realpath("/proc/self/exe".(i8))
	if self_path < 0 {
		self_path = ori_execout
	}
}
fn runtimeinit(){
	os.setsignal(os.SIGSEGV,std.segsegvrecv)
	pools_init()
	debug.debug_init()
}

fn segsegv_handler(sig<u32>,info<Siginfo> , ctxt<u64>){
	fmt.println("\npanicked! stack backtrace:")
	buf_o<i8:10> = null
	rip<u64> = segsegv_rip(ctxt)
	//self path
	selfpath = string.new(self_path)
	if debug.enabled == 1
		fmt.println("0: " + debug.findpc(rip))
	else {
		buf<i8*>	 = &buf_o
		std.itoa(rip,buf,16.(i8))
		os.shell(
			fmt.sprintf(
				"addr2line -e %s 0x%s",
				selfpath,
				string.new(buf)
			)
		)
	}
	bp<u64*> = runtime.get_bp()
	//skip first stack
	bp = *bp
	i = 1
	//stack backtrace 
	loop {
		pc<u64*> = bp + 8
		rip<u64> = *pc
		if rip == null break
		if debug.enabled == 1 {
			fmt.println(i + ": " + debug.findpc(rip))
		}else {
			buf<i8*>	 = &buf_o
			std.itoa(rip,buf,16.(i8))
			os.shell(fmt.sprintf(
					"addr2line -e %s 0x%s",
					selfpath,
					string.new(buf)
				)
			)
		}
		bp = *bp
		i += 1
	}
	os.exit(ErrorCode)
}
mem Stackt {
	i8* ss_sp
	i32 ss_flags
	i8 pad_cgo_0[4]
	u64 ss_size
}
mem Ucontext  {
	u64 	uc_flags   
	Ucontext* uc_link      
	Stackt uc_stack
	u64 uc_mcontext
}
mem Sigcontext {
	u64 r8,r9,r10,r11,r12,r13,r14,r15,rdi,rsi,rbp,rbx,rdx,rax,rcx,rsp,rip,eflags
	u16 cs,gs,fs,__pad0
	u64 err,trapno,oldmask,cr2
	//fpstate1*     *fpstate
	// u64 __reserved1[8]
}
fn segsegv_rip(ctxt<Ucontext>) {
	sigc<Sigcontext> = &ctxt.uc_mcontext
	return sigc.rip
}