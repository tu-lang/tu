
use os
use std
use string
use fmt
use runtime.gc

Dtrue  = true
Dfalse = false
# start at core space init
ori_envp<u64*>
ori_argc<u64>
ori_argv<u64>
ori_envs<u64>

ErrorCode<i32> = -1

func args_init(argc<u64>, argv<u64*>){
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
		str.data = string.stringnew(*argv)
		arr_pushone(arr,str)
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
		str1.data = string.stringnew(*envp)
		arr_pushone(envs,str1)
		envp += PointerSize
	}
	ori_envs = envs
}
func runtimeinit(){
	os.setsignal(os.SIGSEGV,segsegv_handler)
}

func segsegv_handler(sig<u32>,info<Siginfo> , ctxt<u64>){
	fmt.println("panicked! stack backtrace:\n")
	rip<u64> = segsegv_rip(ctxt)
	fmt.print("0: ")
	os.shell("ta2l ./a.out " + int(rip))
	bp<u64*> = gc.get_bp()
	//skip first stack
	bp = *bp
	i = 1
	//stack backtrace 
	while True {
		pc<u64*> = bp + 8
		rip<u64> = *pc
		if rip == null break
		fmt.print(i + ": ")
		os.shell("ta2l ./a.out " + int(rip))
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
func segsegv_rip(ctxt<Ucontext>) {
	sigc<Sigcontext> = &ctxt.uc_mcontext
	return sigc.rip
}