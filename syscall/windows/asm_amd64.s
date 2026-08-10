# Windows process entry. link.exe /ENTRY:mainCRTStartup (Win64 rcx unused).
# Internal Tu calls stay SysV; kernel32 is thunked in sys_*.s.
.text
.globl mainCRTStartup
mainCRTStartup:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	call win_init_stdio
	call std_stdinit
	call runtime_osinit
	xor %edi, %edi
	xor %esi, %esi
	xor %edx, %edx
	# Win64: RSP 16-aligned at call; 3 arg pushes need an 8-byte pad first.
	sub $8, %rsp
	push %rdx
	push %rsi
	push %rdi
	call runtime_args_init
	call runtime_runtimeinit
	call main_init.0
	call main_main
	xor %edi, %edi
	call std_die
