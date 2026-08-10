# Windows std_* : SysV in, Win64 kernel32 out.
.text

.globl win_init_stdio
win_init_stdio:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov $-10, %ecx
	call GetStdHandle
	lea win_fds(%rip), %rdx
	mov %rax, 0(%rdx)
	mov $-11, %ecx
	call GetStdHandle
	lea win_fds(%rip), %rdx
	mov %rax, 8(%rdx)
	mov $-12, %ecx
	call GetStdHandle
	lea win_fds(%rip), %rdx
	mov %rax, 16(%rdx)
	mov %rbp, %rsp
	pop %rbp
	ret

win_fd_get:
	cmp $0, %rdi
	jl win_fd_bad
	cmp $256, %rdi
	jge win_fd_bad
	lea win_fds(%rip), %rax
	shl $3, %rdi
	add %rdi, %rax
	mov (%rax), %rax
	ret
win_fd_bad:
	xor %rax, %rax
	ret

win_fd_alloc:
	push %rbx
	mov %rdi, %rbx
	mov $3, %ecx
win_fd_al:
	cmp $256, %ecx
	jge win_fd_af
	mov %ecx, %edx
	shl $3, %rdx
	lea win_fds(%rip), %rax
	add %rdx, %rax
	mov (%rax), %r8
	cmp $0, %r8
	jne win_fd_an
	mov %rbx, (%rax)
	mov %ecx, %eax
	pop %rbx
	ret
win_fd_an:
	add $1, %ecx
	jmp win_fd_al
win_fd_af:
	mov $-1, %eax
	pop %rbx
	ret

.global std_open
std_open:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $80, %rsp
	mov %rdi, %r12
	mov %rsi, %rbx
	mov %ebx, %eax
	and $3, %eax
	cmp $1, %eax
	je so_w
	cmp $2, %eax
	je so_rw
	mov $0x80000000, %edx
	jmp so_acc
so_w:
	mov $0x40000000, %edx
	jmp so_acc
so_rw:
	mov $0xC0000000, %edx
so_acc:
	mov %ebx, %eax
	and $576, %eax
	cmp $576, %eax
	jne so_d1
	movl $2, 32(%rsp)
	jmp so_call
so_d1:
	mov %ebx, %eax
	and $64, %eax
	cmp $0, %eax
	je so_d2
	movl $4, 32(%rsp)
	jmp so_call
so_d2:
	movl $3, 32(%rsp)
so_call:
	movl $128, 40(%rsp)
	movq $0, 48(%rsp)
	mov %r12, %rcx
	xor %r8, %r8
	xor %r9, %r9
	call CreateFileA
	cmp $-1, %rax
	je so_err
	mov %rax, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je so_err
	movsxd %eax, %rax
	jmp so_out
so_err:
	mov $-22, %rax
so_out:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global std_read
std_read:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	mov %r12, %rdi
	call win_fd_get
	cmp $0, %rax
	je sr_err
	mov %rax, %rcx
	mov %r13, %rdx
	mov %rbx, %r8
	lea 40(%rsp), %r9
	movq $0, 32(%rsp)
	call ReadFile
	cmp $0, %eax
	je sr_err
	mov 40(%rsp), %eax
	movsxd %eax, %rax
	jmp sr_out
sr_err:
	mov $-9, %rax
sr_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global std_write
std_write:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	mov %r12, %rdi
	call win_fd_get
	cmp $0, %rax
	je sw_err
	mov %rax, %rcx
	mov %r13, %rdx
	mov %rbx, %r8
	lea 40(%rsp), %r9
	movq $0, 32(%rsp)
	call WriteFile
	cmp $0, %eax
	je sw_err
	mov 40(%rsp), %eax
	movsxd %eax, %rax
	jmp sw_out
sw_err:
	mov $-9, %rax
sw_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global std_close
std_close:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rbx
	cmp $3, %rbx
	jl sc_ok0
	call win_fd_get
	cmp $0, %rax
	je sc_err
	mov %rax, %rcx
	call CloseHandle
	mov %rbx, %rdi
	shl $3, %rdi
	lea win_fds(%rip), %rax
	add %rdi, %rax
	movq $0, (%rax)
sc_ok0:
	xor %eax, %eax
	jmp sc_out
sc_err:
	mov $-9, %rax
sc_out:
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.global std_seek
std_seek:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	mov %r12, %rdi
	call win_fd_get
	cmp $0, %rax
	je sk_err
	mov %rax, %rcx
	mov %r13, %rdx
	lea 32(%rsp), %r8
	mov %rbx, %r9
	call SetFilePointerEx
	cmp $0, %eax
	je sk_err
	mov 32(%rsp), %rax
	jmp sk_out
sk_err:
	mov $-22, %rax
sk_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global std_die
std_die:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %edi, %ecx
	call ExitProcess
	jmp std_die

.global std_brk
std_brk:
	mov win_brk_pos(%rip), %rax
	cmp $0, %rax
	jne brk_ready
	push %rdi
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	xor %ecx, %ecx
	mov $0x4000000, %edx
	mov $0x3000, %r8
	mov $4, %r9
	call VirtualAlloc
	mov %rbp, %rsp
	pop %rbp
	pop %rdi
	cmp $0, %rax
	je brk_fail
	mov %rax, win_brk_base(%rip)
	mov %rax, win_brk_pos(%rip)
	add $0x4000000, %rax
	mov %rax, win_brk_limit(%rip)
	mov win_brk_pos(%rip), %rax
brk_ready:
	cmp $0, %rdi
	jne brk_set
	mov win_brk_pos(%rip), %rax
	retq
brk_set:
	mov win_brk_base(%rip), %rax
	cmp %rax, %rdi
	setb %cl
	cmp $0, %cl
	jne brk_fail
	mov win_brk_limit(%rip), %rax
	cmp %rdi, %rax
	setb %cl
	cmp $0, %cl
	jne brk_fail
	mov %rdi, win_brk_pos(%rip)
	mov %rdi, %rax
	retq
brk_fail:
	xor %rax, %rax
	retq

.globl std_nanosleep
std_nanosleep:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov 0(%rdi), %rax
	mov $1000, %rcx
	imul %rcx, %rax
	mov %rax, %rbx
	mov 8(%rdi), %rax
	xor %rdx, %rdx
	mov $1000000, %rcx
	div %rcx
	add %rbx, %rax
	cmp $0, %rax
	jne ns_ok
	mov $1, %eax
ns_ok:
	mov %eax, %ecx
	call Sleep
	xor %eax, %eax
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.globl std_getdents
std_getdents:
	mov $-38, %rax
	retq

.globl std_stat
std_stat:
	mov $-38, %rax
	retq

.globl std_fstat
std_fstat:
	mov $-38, %rax
	retq

.globl std_lstat
std_lstat:
	mov $-38, %rax
	retq

.globl std_execve
std_execve:
	mov $-38, %rax
	retq

.globl std_time
std_time:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %rbx
	lea 32(%rsp), %rcx
	call GetSystemTimeAsFileTime
	mov 32(%rsp), %rax
	mov win_unix_epoch(%rip), %rcx
	sub %rcx, %rax
	mov $10000000, %rcx
	xor %rdx, %rdx
	div %rcx
	cmp $0, %rbx
	je tm_out
	mov %rax, (%rbx)
tm_out:
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.globl std_clock_gettime
std_clock_gettime:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $48, %rsp
	mov %rsi, %rbx
	lea 32(%rsp), %rcx
	call GetSystemTimeAsFileTime
	mov 32(%rsp), %rax
	mov win_unix_epoch(%rip), %rcx
	sub %rcx, %rax
	mov $10000000, %rcx
	xor %rdx, %rdx
	div %rcx
	mov %rax, 0(%rbx)
	mov %rdx, %rax
	mov $100, %rcx
	imul %rcx, %rax
	mov %rax, 8(%rbx)
	xor %eax, %eax
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.globl std_sigreturn
std_sigreturn:
	retq

.globl std_sigreturn_pc
std_sigreturn_pc:
	lea std_sigreturn(%rip), %rax
	retq

.globl std_sigtramp_pc
std_sigtramp_pc:
	xor %rax, %rax
	retq

.globl std_rt_sigaction
std_rt_sigaction:
	xor %eax, %eax
	retq

.globl std_mmap
std_mmap:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %r12
	mov %rsi, %rbx
	cmp $0, %rdx
	jne mm_rw
	mov $0x2000, %r8
	mov $1, %r9
	jmp mm_call
mm_rw:
	cmp $0, %r12
	jne mm_commit
	mov $0x3000, %r8
	mov $4, %r9
	jmp mm_call
mm_commit:
	mov $0x1000, %r8
	mov $4, %r9
mm_call:
	mov %r12, %rcx
	mov %rbx, %rdx
	call VirtualAlloc
	cmp $0, %rax
	jne mm_ok
	xor %rax, %rax
mm_ok:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

.globl std_madvise
std_madvise:
	xor %eax, %eax
	retq

.globl std_munmap
std_munmap:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	xor %edx, %edx
	mov $0x8000, %r8
	call VirtualFree
	cmp $0, %eax
	jne mu_ok
	mov $-22, %rax
	jmp mu_out
mu_ok:
	xor %eax, %eax
mu_out:
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_segsegvrecv
std_segsegvrecv:
	push %rdx
	push %rsi
	push %rdi
	call runtime_segsegv_handler
	add $24, %rsp
	retq

.globl std_segsegvrecv_pc
std_segsegvrecv_pc:
	lea std_segsegvrecv(%rip), %rax
	retq

.globl std_readlink
std_readlink:
	mov $-38, %rax
	retq

.global std_cputicks
std_cputicks:
	rdtscp
	shl $0x20, %rdx
	add %rdx, %rax
	retq

.globl std_gettid
std_gettid:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	call GetCurrentThreadId
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_signalfd4
std_signalfd4:
	mov $-38, %rax
	retq

.globl std_rt_sigprocmask
std_rt_sigprocmask:
	xor %eax, %eax
	retq

.globl std_pidfd_open
std_pidfd_open:
	mov $-38, %rax
	retq

.globl std_wait4
std_wait4:
	mov $-38, %rax
	retq

.globl std_fork
std_fork:
	mov $-38, %rax
	retq

.globl std_dup2
std_dup2:
	mov $-38, %rax
	retq

.globl std_pipe2
std_pipe2:
	mov $-38, %rax
	retq

.data
.align 8
win_fds:
	.zero 2048
win_brk_base:
	.quad 0
win_brk_pos:
	.quad 0
win_brk_limit:
	.quad 0
win_unix_epoch:
	.quad 116444736000000000
