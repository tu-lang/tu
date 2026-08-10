.text
.globl runtime_get_sp
runtime_get_sp:
	movq %rsp, %rax
	ret
.globl runtime_get_bp
runtime_get_bp:
	movq %rbp, %rax
	ret
.globl runtime_get_di
runtime_get_di:
	movq %rdi, %rax
	ret
.globl runtime_get_si
runtime_get_si:
	movq %rsi, %rax
	ret
.globl runtime_get_dx
runtime_get_dx:
	movq %rdx, %rax
	ret
.globl runtime_get_cx
runtime_get_cx:
	movq %rcx, %rax
	ret
.globl runtime_get_r8
runtime_get_r8:
	movq %r8, %rax
	ret
.globl runtime_get_r9
runtime_get_r9:
	movq %r9, %rax
	ret
.globl runtime_get_ax
runtime_get_ax:
	movq %rax, %rax
	ret
.globl runtime_get_bx
runtime_get_bx:
	movq %rbx, %rax
	ret
.globl runtime_get_r12
runtime_get_r12:
	movq %r12, %rax
	ret
.globl runtime_get_r13
runtime_get_r13:
	movq %r13, %rax
	ret
.globl runtime_get_r14
runtime_get_r14:
	movq %r14, %rax
	ret
.globl runtime_get_r15
runtime_get_r15:
	movq %r15, %rax
	ret
.globl runtime_callerpc
runtime_callerpc:
	mov 8(%rbp), %rax
	ret
.globl runtime_gcmentryptr
runtime_gcmentryptr:
	lea gc.ms.entry(%rip), %rax
	ret

.globl runtime_settls
runtime_settls:
	retq

runtime_ensure_tls:
	lea win_tls_ready(%rip), %rax
	mov (%rax), %eax
	cmp $2, %eax
	je et_done
	lea win_tls_ready(%rip), %rdi
	xor %eax, %eax
	mov $1, %edx
	lock
	cmpxchgl %edx, (%rdi)
	jne et_wait
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	call TlsAlloc
	mov %eax, win_tls_index(%rip)
	lea win_tls_ready(%rip), %rcx
	movl $2, (%rcx)
	mov %rbp, %rsp
	pop %rbp
	ret
et_wait:
	lea win_tls_ready(%rip), %rax
et_spin:
	mov (%rax), %ecx
	cmp $2, %ecx
	je et_done
	pause
	jmp et_spin
et_done:
	ret

.global runtime_core
runtime_core:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	call runtime_ensure_tls
	mov win_tls_index(%rip), %ecx
	call TlsGetValue
	mov %rbp, %rsp
	pop %rbp
	ret

.global runtime_setcore
runtime_setcore:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rbx
	call runtime_ensure_tls
	mov win_tls_index(%rip), %ecx
	mov %rbx, %rdx
	call TlsSetValue
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	ret

.globl runtime_clone
runtime_clone:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $48, %rsp
	mov %rdx, %r12
	mov %rcx, %r13
	mov %r8, %r14
	mov %r9, %r15
	sub $24, %r15
	mov %r13, 0(%r15)
	mov %r14, 8(%r15)
	mov %r12, 16(%r15)
	xor %ecx, %ecx
	xor %edx, %edx
	lea win_thread_start(%rip), %r8
	mov %r15, %r9
	movq $0, 32(%rsp)
	movq $0, 40(%rsp)
	call CreateThread
	cmp $0, %rax
	je cl_fail
	mov %rax, %rcx
	call CloseHandle
	mov $1, %eax
	jmp cl_out
cl_fail:
	mov $-1, %eax
cl_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	ret

.globl win_thread_start
win_thread_start:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $16, %rsp
	mov %rcx, %rbx
	mov 16(%rbx), %r12
	mov 0(%rbx), %rax
	mov 8(%rbx), %rdi
	sub $8, %rsp
	push %rdi
	call *%rax
	add $16, %rsp
	xor %eax, %eax
	mov %eax, (%r12)
	mov %r12, %rdi
	mov $1, %esi
	xor %edx, %edx
	xor %ecx, %ecx
	xor %r8, %r8
	xor %r9, %r9
	call runtime_futex
	xor %ecx, %ecx
	call ExitThread
	pop %r12
	pop %rbx
	pop %rbp
	ret

.globl runtime_procyield
runtime_procyield:
py1:
	pause
	sub $0x1, %rdi
	jne py1
	ret

.globl runtime_osyield_sys
runtime_osyield_sys:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	xor %ecx, %ecx
	call Sleep
	mov %rbp, %rsp
	pop %rbp
	ret

.globl runtime_futex
runtime_futex:
	mov %rsi, %rax
	and $0x7f, %rax
	cmp $0, %rax
	je fx_wait
	cmp $1, %rax
	je fx_wake
	mov $-22, %rax
	ret
fx_wait:
	push %rbp
	mov %rsp, %rbp
	push %r12
	push %r13
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r12
	mov %rdx, %r13
	mov $0xFFFFFFFF, %r9
	cmp $0, %rcx
	je fx_do
	mov 0(%rcx), %eax
	movsxd %eax, %rax
	mov $1000, %r8
	imul %r8, %rax
	cmp $0, %rax
	jne fx_ms
	mov $1, %rax
fx_ms:
	mov %rax, %r9
fx_do:
	mov %r13, 32(%rsp)
	mov %r12, %rcx
	lea 32(%rsp), %rdx
	mov $4, %r8
	call WaitOnAddress
	xor %eax, %eax
	lea -16(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbp
	ret
fx_wake:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call WakeByAddressAll
	xor %eax, %eax
	mov %rbp, %rsp
	pop %rbp
	ret

.data
.globl runtime_pclntab
runtime_pclntab:
	.long 0xFFFFFFF2
	.long 0x00000801
	.long 0
	.long 0
	.long 24
	.long 0
.globl runtime_pclntab_end
runtime_pclntab_end:
	.byte 0
.align 8
.globl runtime_core_slot
runtime_core_slot:
	.quad 0
win_tls_index:
	.long 0
win_tls_ready:
	.long 0
.globl runtime_jmpbuf_pool
runtime_jmpbuf_pool:
	.zero 4096

.text
.globl runtime_pclntab_addr
runtime_pclntab_addr:
	lea runtime_pclntab(%rip), %rax
	ret
.globl runtime_pclntab_end_addr
runtime_pclntab_end_addr:
	lea runtime_pclntab_end(%rip), %rax
	ret
.globl runtime_setjmp
runtime_setjmp:
	mov %rbx, 0(%rdi)
	mov %rbp, 8(%rdi)
	mov %r12, 16(%rdi)
	mov %r13, 24(%rdi)
	mov %r14, 32(%rdi)
	mov %r15, 40(%rdi)
	lea 8(%rsp), %rax
	mov %rax, 48(%rdi)
	mov (%rsp), %rax
	mov %rax, 56(%rdi)
	mov $0, %rax
	ret
.globl runtime_longjmp
runtime_longjmp:
	mov %rsi, %rax
	cmp $0, %rax
	jne lj_ok
	mov $1, %rax
lj_ok:
	mov 0(%rdi), %rbx
	mov 8(%rdi), %rbp
	mov 16(%rdi), %r12
	mov 24(%rdi), %r13
	mov 32(%rdi), %r14
	mov 40(%rdi), %r15
	mov 48(%rdi), %rsp
	mov 56(%rdi), %rcx
	jmp *%rcx
.globl runtime_jmpbuf_pool_addr
runtime_jmpbuf_pool_addr:
	lea runtime_jmpbuf_pool(%rip), %rax
	ret
