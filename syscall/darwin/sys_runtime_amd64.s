# Darwin runtime helpers: registers, TLS (global for ST MVP), ulock futex, clone stub.
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
	# Must use (%rip): bare "lea sym, %rax" encodes as leal→%eax and truncates VA above 4G (Darwin base 0x100000000).
	lea gc.ms.entry(%rip), %rax
	ret

# Darwin has no Linux arch TLS slot; settls is a no-op (Core via pthread_key).
.globl runtime_settls
runtime_settls:
	retq

# Ensure pthread_key for per-thread Core* (once; CAS 0→1 create, 2=ready).
# ready: 0=uninit, 1=creating, 2=ready. Avoids dual pthread_key_create races.
runtime_ensure_core_key:
	lea runtime_core_key_ready(%rip), %rax
	mov (%rax), %eax
	cmp $2, %eax
	je ensure_core_key_done
	lea runtime_core_key_ready(%rip), %rdi
	xor %eax, %eax
	mov $1, %edx
	lock
	cmpxchgl %edx, (%rdi)
	jne ensure_core_key_wait
	lea runtime_core_key(%rip), %rdi
	xor %esi, %esi
	call _pthread_key_create
	lea runtime_core_key_ready(%rip), %rax
	mov $2, %ecx
	mov %ecx, (%rax)
	ret
ensure_core_key_wait:
	lea runtime_core_key_ready(%rip), %rax
ensure_core_key_spin:
	mov (%rax), %ecx
	cmp $2, %ecx
	je ensure_core_key_done
	pause
	jmp ensure_core_key_spin
ensure_core_key_done:
	ret

.global runtime_core
runtime_core:
	push %rbp
	mov %rsp, %rbp
	call runtime_ensure_core_key
	lea runtime_core_key(%rip), %rax
	mov (%rax), %rdi
	call _pthread_getspecific
	pop %rbp
	ret

.global runtime_setcore
runtime_setcore:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	mov %rdi, %rbx
	call runtime_ensure_core_key
	lea runtime_core_key(%rip), %rax
	mov (%rax), %rdi
	mov %rbx, %rsi
	call _pthread_setspecific
	pop %rbx
	pop %rbp
	ret

# clone(flags, stack, ctid, fn, arg, tls) — Darwin: pthread_create + manual clear_tid.
# SysV: rdi=flags rsi=stack rdx=ctid rcx=fn r8=arg r9=tls
# Caller passes tls_hi (one past end of THREAD_TLS_SIZE), same as Linux settls.
# Pack fn/arg/ctid into the last 24 bytes below tls_hi (never write at/past tls_hi).
# Ignores flags/stack (pthread provides the stack). Returns 1 / -1 for newosthread.
.globl runtime_clone
runtime_clone:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	# After 5 pushes rsp is 8-mod-16; sub $88 → 16-aligned for calls.
	sub $88, %rsp
	mov %rdx, %r12
	mov %rcx, %r13
	mov %r8, %r14
	mov %r9, %r15
	sub $24, %r15
	# pack[0]=fn pack[8]=arg pack[16]=ctid*
	mov %r13, 0(%r15)
	mov %r14, 8(%r15)
	mov %r12, 16(%r15)
	# attr at 0(%rsp), pthread_t at 64(%rsp)
	mov %rsp, %rdi
	call _pthread_attr_init
	cmp $0, %eax
	jne runtime_clone_fail
	mov %rsp, %rdi
	mov $2, %esi
	call _pthread_attr_setdetachstate
	cmp $0, %eax
	jne runtime_clone_fail_attr
	lea 64(%rsp), %rdi
	mov %rsp, %rsi
	lea runtime_pthread_start(%rip), %rdx
	mov %r15, %rcx
	call _pthread_create
	mov %eax, %ebx
	mov %rsp, %rdi
	call _pthread_attr_destroy
	cmp $0, %ebx
	jne runtime_clone_fail
	mov $1, %eax
	jmp runtime_clone_out
runtime_clone_fail_attr:
	mov %rsp, %rdi
	call _pthread_attr_destroy
runtime_clone_fail:
	mov $-1, %eax
runtime_clone_out:
	add $88, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	ret

# pthread start: call Tu fn(arg) with stack ABI, then zero clear_tid + ulock wake.
# SysV: at thread entry rsp≡8 (mod 16). Keep ctid* in stack slot — Tu clobbers r15.
.globl runtime_pthread_start
runtime_pthread_start:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	sub $16, %rsp
	mov %rdi, %rbx
	mov 16(%rbx), %rax
	mov %rax, -24(%rbp)
	mov 0(%rbx), %r12
	mov 8(%rbx), %rdi
	sub $8, %rsp
	push %rdi
	call *%r12
	add $8, %rsp
	mov -24(%rbp), %rdi
	xor %eax, %eax
	mov %eax, (%rdi)
	mov $1, %esi
	xor %edx, %edx
	xor %ecx, %ecx
	xor %r8, %r8
	xor %r9, %r9
	call runtime_futex
	xor %edi, %edi
	call _pthread_exit
	mov %rbp, %rsp
	pop %rbp
	ret

.globl runtime_procyield
runtime_procyield:
rsp1:
	pause
	sub $0x1, %rdi
	jne rsp1
	ret

.globl runtime_osyield_sys
runtime_osyield_sys:
	# Match Linux sched_yield: let other cores/workers run (spin_until / STW).
	push %rbp
	mov %rsp, %rbp
	call _sched_yield
	pop %rbp
	ret

# Map Linux futex ops onto ulock_wait / ulock_wake.
# WAIT (0/128): ulock_wait(UL_COMPARE_AND_WAIT=1, addr, val, timeout_us=0)
# WAKE (1/129): ulock_wake(UL_COMPARE_AND_WAIT=1, addr, 0)
.globl runtime_futex
runtime_futex:
	mov %rsi, %rax
	and $0x7f, %rax
	cmp $0, %rax
	je futex_wait
	cmp $1, %rax
	je futex_wake
	mov $-22, %rax
	ret
futex_wait:
	# args in: rdi=addr rsi=op rdx=val rcx=ts (TimeSpec* or null)
	# ulock_wait(op=1, addr, val, timeout_us); timeout_us=0 means infinite.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	mov %rdi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	cmp $0, %r14
	je futex_wait_infinite
	mov 0(%r14), %rax
	mov $1000000, %r10
	imul %r10, %rax
	mov %rax, %r11
	mov 8(%r14), %rax
	xor %rdx, %rdx
	mov $1000, %r10
	div %r10
	add %rax, %r11
	cmp $0, %r11
	jne futex_wait_clamp
	mov $1, %r11
futex_wait_clamp:
	mov $0xFFFFFFFF, %rcx
	cmp %rcx, %r11
	jbe futex_wait_have_us
	mov %rcx, %r11
futex_wait_have_us:
	mov %r11, %r10
	jmp futex_wait_do
futex_wait_infinite:
	xor %r10, %r10
futex_wait_do:
	mov $1, %rdi
	mov %r12, %rsi
	mov %r13, %rdx
	mov $0x2000203, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne futex_wait_err
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	ret
futex_wait_err:
	mov %rax, %rdi
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	jmp futex_err
futex_wake:
	# ulock_wake(op=1, addr, 0)
	mov %rdi, %rsi
	mov $1, %edi
	xor %rdx, %rdx
	mov $0x2000204, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne futex_wake_err
	ret
futex_wake_err:
	# ENOENT: no waiters — success (libdispatch treats the same).
	cmp $2, %rax
	jne futex_err
	xor %rax, %rax
	ret
futex_err:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
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
# Legacy global Core slot (unused; Core is pthread_key TLS).
.globl runtime_core_slot
runtime_core_slot:
	.quad 0
.globl runtime_core_key
runtime_core_key:
	.quad 0
.globl runtime_core_key_ready
runtime_core_key_ready:
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
	jne runtime_longjmp_ok
	mov $1, %rax
runtime_longjmp_ok:
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
