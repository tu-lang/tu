use std

EMPTY_MASK<u64> = 0xFFFFFFFFFFFFFFFF
Null<i32> = 0
_SA_RESTART<u64>  = 0x10000000
_SA_ONSTACK<u64>  = 0x8000000
_SA_RESTORER<u64> = 0x4000000
_SA_SIGINFO<u64>  = 0x4

mem Sigactiont  {
	u64 sa_handler,sa_flags,sa_restorer,sa_mask
}

func setsig(i<u32> , fn<u64>) {
	sa<Sigactiont> = new Sigactiont
	sa.sa_flags = _SA_SIGINFO | _SA_ONSTACK | _SA_RESTORER | _SA_RESTART
	sa.sa_mask = EMPTY_MASK

	sa.sa_restorer = std.sigreturn
	sa.sa_handler = fn
	mask_size<i32> = 8
	std.rt_sigaction(i, sa, Null,mask_size)
}