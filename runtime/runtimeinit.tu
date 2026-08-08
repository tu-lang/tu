
use os
use std
use string
use fmt
use runtime
use runtime.debug

// scheduler init
coretlssize<i64> = 48
core0<Core:>
coretls<i64:6>
sched<Sched:>

// start at core space init
ori_envp<u64*>
ori_argc<u64>
ori_argv<u64>
ori_envs<u64>
ori_execout<u64*>
self_path<i8*>
ErrorCode<i32> = -1
fn gcmentryptr() 

fn osinit(){
	//TODOGC: sysconf
	ncpu = 4
	physPageSize = 4096
	gcphase = _GCoff
	gcBlackenEnabled = false
	settls(&coretls + coretlssize)
	setcore(&core0)
    core0.stktop = get_bp()
    core0.pid = std.gettid()
	//sched init
	sched.gcwaiting = 0
	sched.allcores  = null
	sched.cores     = 0
	sched.cid       = 0
	sched.debug   	= null
	//gc init
	gc.startSema.sema = 1
	worldsema.sema = 1
	heap_.sweepdone = 1
	gc.heapmarked = heapmin / 2
	gc.setpercent(100.(i8))
	//malloc init
	mallocinit()
	//sys core init
	core0.init()
    core0.status = CoreRun
    sched.addcore(&core0)
	// gc enable
	gc.enablegc = true
}

fn mallocinit() {
	heap_.lock.init()
	heap_.init()
	//set local cache
	core0.local = allocmcache()
	heap_.allspans.init(ARRAY_SIZE,PointerSize)
	heap_.allarenas.init(ARRAY_SIZE,PointerSize)
	heap_.sweeparenas.init(ARRAY_SIZE,PointerSize)

	c0<u64> = 0xc0
    for i<i32> = 0x7f; i >= 0; i -= 1 {
		p<u64> = 0
		p = i<<40 | (u64Mask & (c0<<32) )
		hint<ArenaHint> = heap_.arenaHintAlloc.alloc()
		hint.addr = p
		hint.next = heap_.arenaHints
		heap_.arenaHints = hint
	}
	while(gcphase != _GCoff){}
}

fn args_init(argc<u64>, argv<u64*>, envp_in<u64*>){
	// argv[0] is the program path on both Linux and Darwin (dyld passes
	// argc/argv/envp in registers; Linux crt used to read a pre-argv stack word).
	ori_execout = null
	if argv != null {
		if *argv != null {
			ori_execout = *argv
		}
	}
	// Linux: envp_in==null → envp follows argv's NULL (contiguous stack).
	// Darwin LC_MAIN: envp is a separate pointer — must pass it explicitly.
	envp<u64*> = envp_in
	if envp == null {
		envp = argv + (argc + 1.(u64)) * PointerSize
	}
	c = int(argc)
	c -= 1
	ori_envp = envp
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
	// Linux: /proc/self/exe. Darwin has no /proc — realpath returns null;
	// fall back to argv[0].
	self_path = std.realpath("/proc/self/exe".(i8))
	if self_path == null {
		self_path = ori_execout
	}
}
fn runtimeinit(){
	// Must pass raw code PC — std.segsegvrecv as a value is a heap descriptor.
	os.setsignal(os.SIGSEGV,std.segsegvrecv_pc())
	pools_init()
	debug.debug_init()
}

fn segsegv_handler(sig<u32>,info<Siginfo> , ctxt<u64>){
	// Avoid recursive SIGSEGV while unwinding.
	os.setsignal(os.SIGSEGV,0.(u64))
	println(*"\npanicked! stack backtrace:")
	// Platform-specific: linux.tu / darwin.tu implement segsegv_rip.
	rip<u64> = segsegv_rip(ctxt)
	// L2a: pclntab only; never fork addr2line
	pc = debug.findpc(rip)
	println(*"0: %s" ,*pc)
	// Optional rbp frames: linux.tu walks; darwin.tu is a no-op (sigtramp).
	segsegv_walkstack()
	// os.exit expects a pointer operand (*code); use std.die for a raw code.
	std.die(ErrorCode.(i8))
}
