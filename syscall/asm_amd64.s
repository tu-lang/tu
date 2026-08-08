.text
    .global main
main:
	call std_stdinit
	call runtime_osinit
    mov (%rsp),%rdi
    lea 16(%rsp),%rsi
	# Linux: envp follows argv NULL; pass null so args_init derives it.
	xor %rdx, %rdx
	push %rdx
	push %rsi
	push %rdi
	call runtime_args_init
	call runtime_runtimeinit
	call main_init.0
	call main_main
	mov $0,%rdi
	call std_die
    leaveq
    retq
	