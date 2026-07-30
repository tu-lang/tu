use std

EMPTY_MASK<u64> = 0xFFFFFFFFFFFFFFFF
Null<i32> = 0
_SA_RESTART<u64>  = 0x10000000
_SA_ONSTACK<u64>  = 0x8000000
_SA_RESTORER<u64> = 0x4000000
_SA_SIGINFO<u64>  = 0x4

SIGHUP<i32> = 1       SIGINT<i32> = 2       SIGQUIT<i32> = 3      SIGILL<i32>  = 4       SIGTRAP<i32> = 5
SIGABRT<i32> = 6      SIGBUS<i32>  = 7       SIGFPE<i32>  = 8       SIGKILL<i32> = 9     SIGUSR1<i32> = 10
SIGSEGV<i32> = 11     SIGUSR2<i32> = 12     SIGPIPE<i32> = 13     SIGALRM<i32> = 14      SIGTERM<i32> = 15
SIGSTKFLT<i32> = 16   SIGCHLD<i32> = 17     SIGCONT<i32> = 18     SIGSTOP<i32> = 19      SIGTSTP<i32> = 20
SIGTTIN<i32> = 21     SIGTTOU<i32> = 22     SIGURG<i32> = 23      SIGXCPU<i32> = 24      SIGXFSZ<i32> = 25
SIGVTALRM<i32> = 26   SIGPROF<i32> = 27     SIGWINCH<i32> = 28    SIGIO<i32>   = 29      SIGPWR<i32>  = 30
SIGSYS<i32>  = 31     SIGRTMIN<i32> = 34    

mem Sigactiont  {
	u64 sa_handler,sa_flags,sa_restorer,sa_mask
}

// Install a SA_SIGINFO handler. Always set SA_RESTORER to the raw
// std.sigreturn_pc() address — Tu `sigreturn.(u64)` is a heap descriptor
// and must not be used as sa_restorer (kernel would jump there → SEGV at
// NULL). Do not set SA_ONSTACK without a configured sigaltstack.
func setsignal(i<u32> , fc<u64>) {
	sa<Sigactiont> = new Sigactiont
	sa.sa_flags = _SA_SIGINFO | _SA_RESTART | _SA_RESTORER
	sa.sa_mask = EMPTY_MASK
	sa.sa_restorer = std.sigreturn_pc()
	sa.sa_handler = fc
	mask_size<i32> = 8
	std.rt_sigaction(i, sa, Null,mask_size)
}