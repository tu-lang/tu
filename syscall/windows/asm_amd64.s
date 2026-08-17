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
	# Real argv/env: raw pointers parsed by runtime_win_args_init (Tu side).
	call GetCommandLineA
	mov %rax, %rbx
	call GetEnvironmentStringsA
	# Win64: RSP 16-aligned at call; 2 arg pushes keep alignment.
	push %rax
	push %rbx
	call runtime_win_args_init
	call runtime_runtimeinit
	call main_init.0
	call main_main
	xor %edi, %edi
	call std_die
