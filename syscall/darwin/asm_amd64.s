# Darwin process entry. dyld LC_MAIN calls _main(argc, argv, envp, apple)
# with SysV registers. argv/envp are separate pointers (not Linux stack layout).
# Tu fn args use the stack: push envp, argv, argc — callee reads at 16/24/32(%rbp).
.text
.globl _main
_main:
	push %rbp
	mov %rsp, %rbp
	# Preserve dyld argc/argv/envp across stdinit/osinit (calls clobber registers).
	push %rdx
	push %rsi
	push %rdi
	call std_stdinit
	call runtime_osinit
	pop %rdi
	pop %rsi
	pop %rdx
	# Tu stack ABI for runtime_args_init(argc, argv, envp).
	push %rdx
	push %rsi
	push %rdi
	call runtime_args_init
	call runtime_runtimeinit
	call main_init.0
	call main_main
	mov $0, %rdi
	call std_die
	leaveq
	retq
