.text
    .global main
main:
	call std_stdinit
	call runtime_mallocinit
	call runtime_gc_init
    mov (%rsp),%rdi
    lea 16(%rsp),%rsi
	push %rsi
	push %rdi
	call runtime_args_init
	call runtime_runtimeinit
	call main_init0
	call main_main
	mov $0,%rdi
	call std_die
    leaveq
    retq
	