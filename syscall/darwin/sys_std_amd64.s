# Darwin BSD syscalls for library/std.
# Numbers are SYS_* | 0x02000000. On error CF=1 and rax=errno;
# convert to Linux-style -errno so Tu callers stay unchanged.
# Asmer has setb (CF) but not jc — use setb + cmp/jne.

.text
.globl std_open
std_open:
	# Remap Linux open flags → Darwin; call libSystem _open.
	push %rbx
	mov %rsi, %rbx
	mov %ebx, %esi
	and $3, %esi
	mov %ebx, %eax
	and $64, %eax
	cmp $0, %eax
	je std_open_nocreat
	add $512, %esi
std_open_nocreat:
	mov %ebx, %eax
	and $512, %eax
	cmp $0, %eax
	je std_open_notrunc
	add $1024, %esi
std_open_notrunc:
	mov %ebx, %eax
	and $1024, %eax
	cmp $0, %eax
	je std_open_noappend
	add $8, %esi
std_open_noappend:
	mov %ebx, %eax
	and $65536, %eax
	cmp $0, %eax
	je std_open_nodir
	add $1048576, %esi
std_open_nodir:
	mov %ebx, %eax
	and $128, %eax
	cmp $0, %eax
	je std_open_noexcl
	add $2048, %esi
std_open_noexcl:
	pop %rbx
	push %rbp
	mov %rsp, %rbp
	call _open
	pop %rbp
	cmp $-1, %rax
	jne std_open_ok
	mov $-22, %rax
std_open_ok:
	retq

.global std_read
std_read:
	push %rbp
	mov %rsp, %rbp
	call _read
	pop %rbp
	cmp $-1, %rax
	jne std_read_ok
	mov $-22, %rax
std_read_ok:
	retq

.global std_close
std_close:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	mov darwin_sfd_kq(%rip), %rax
	cmp $0, %rax
	je std_close_do
	cmp %rax, %rdi
	jne std_close_do
	movq $0, darwin_sfd_kq(%rip)
	movq $0, darwin_sfd_mask(%rip)
std_close_do:
	call _close
	mov %rbp, %rsp
	pop %rbp
	cmp $-1, %rax
	jne std_close_ok
	mov $-22, %rax
std_close_ok:
	retq

.global std_write
std_write:
	push %rbp
	mov %rsp, %rbp
	call _write
	pop %rbp
	cmp $-1, %rax
	jne std_write_ok
	mov $-22, %rax
std_write_ok:
	retq

.global std_seek
std_seek:
	# lseek = 199
	mov $0x20000C7, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.global std_die
std_die:
	# Raw SYS_exit — works after either libSystem or raw fork.
	# rdi holds status (Tu std.die(code<i8>)).
	mov $0x2000001, %rax
	syscall
	jmp std_die

.global std_brk
std_brk:
	# Fake brk over a pre-mapped anonymous arena (Darwin has no brk).
	# Query rdi==0 → current break; else set break and return it (0 on fail).
	mov darwin_brk_pos(%rip), %rax
	cmp $0, %rax
	jne std_brk_ready
	# First use: map 64MiB arena
	push %rdi
	xor %rdi, %rdi
	mov $0x4000000, %rsi
	mov $3, %rdx
	mov $0x1002, %r10
	mov $-1, %r8
	xor %r9, %r9
	mov $0x20000C5, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_brk_init_fail
	mov %rax, darwin_brk_base(%rip)
	mov %rax, darwin_brk_pos(%rip)
	add $0x4000000, %rax
	mov %rax, darwin_brk_limit(%rip)
	mov darwin_brk_pos(%rip), %rax
	pop %rdi
	jmp std_brk_ready
std_brk_init_fail:
	pop %rdi
	xor %rax, %rax
	retq
std_brk_ready:
	cmp $0, %rdi
	jne std_brk_set
	# return current
	mov darwin_brk_pos(%rip), %rax
	retq
std_brk_set:
	mov darwin_brk_base(%rip), %rax
	cmp %rax, %rdi
	setb %cl
	cmp $0, %cl
	jne std_brk_fail
	mov darwin_brk_limit(%rip), %rax
	cmp %rdi, %rax
	setb %cl
	cmp $0, %cl
	jne std_brk_fail
	mov %rdi, darwin_brk_pos(%rip)
	mov %rdi, %rax
	retq
std_brk_fail:
	xor %rax, %rax
	retq

.data
.align 8
darwin_brk_base:
	.quad 0
darwin_brk_pos:
	.quad 0
darwin_brk_limit:
	.quad 0

.text

.globl std_nanosleep
std_nanosleep:
	# Darwin: no Linux SYS_nanosleep; call libSystem nanosleep(req, rem).
	# Args already in %rdi/%rsi (System V). Import via tul dyld allowlist.
	push %rbp
	mov %rsp, %rbp
	call _nanosleep
	pop %rbp
	retq

.globl std_getdents
std_getdents:
	# getdirentries64 → linux_dirent64 (ino@0, off@8, reclen@16, type@18, name@19).
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rdi, %r15
	sub $0x1010, %rsp
	mov %rsp, %r14
	mov $0, %rax
	mov %r14, %rdi
	add $0x1000, %rdi
	mov %rax, 0(%rdi)
	mov %r15, %rdi
	mov %r14, %rsi
	mov %r13, %rdx
	mov %r14, %r10
	add $0x1000, %r10
	mov $0x2000158, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_getdents_syserr
	mov %rax, %r15
	cmp $0, %r15
	je std_getdents_empty
	xor %rbx, %rbx
	xor %r11, %r11
std_getdents_loop:
	cmp %r15, %rbx
	jge std_getdents_done
	mov %r14, %rax
	add %rbx, %rax
	# Darwin: reclen u16@16, namlen u16@18, type u8@20, name@21
	mov 16(%rax), %rcx
	mov %rcx, %rdx
	and $0xffff, %rcx
	shr $16, %rdx
	and $0xffff, %rdx
	cmp $0, %rcx
	je std_getdents_done
	# out_reclen = align8(19+namlen+1)
	mov %rdx, %r8
	add $20, %r8
	add $7, %r8
	shr $3, %r8
	shl $3, %r8
	mov %r11, %r9
	add %r8, %r9
	cmp %r13, %r9
	jg std_getdents_done
	mov %r12, %rdi
	add %r11, %rdi
	mov 0(%rax), %rsi
	mov %rsi, 0(%rdi)
	mov 8(%rax), %rsi
	mov %rsi, 8(%rdi)
	# store u16 reclen at dst+16
	mov %rdi, %rsi
	add $16, %rsi
	mov %r8, %rax
	movb %al, 0(%rsi)
	shr $8, %rax
	add $1, %rsi
	movb %al, 0(%rsi)
	# reload Darwin entry ptr
	mov %r14, %rax
	add %rbx, %rax
	# type @20 → dst+18
	mov %rax, %rsi
	add $20, %rsi
	movb 0(%rsi), %cl
	mov %rdi, %rsi
	add $18, %rsi
	movb %cl, 0(%rsi)
	# name @21 → dst+19
	mov %rax, %rsi
	add $21, %rsi
	mov %rdi, %rax
	add $19, %rax
std_getdents_cpy:
	cmp $0, %rdx
	je std_getdents_cpy_done
	movb 0(%rsi), %cl
	movb %cl, 0(%rax)
	add $1, %rsi
	add $1, %rax
	sub $1, %rdx
	jmp std_getdents_cpy
std_getdents_cpy_done:
	movb $0, 0(%rax)
	mov %r14, %rax
	add %rbx, %rax
	mov 16(%rax), %rcx
	and $0xffff, %rcx
	add %r8, %r11
	add %rcx, %rbx
	jmp std_getdents_loop
std_getdents_done:
	mov %r11, %rax
	jmp std_getdents_epilogue
std_getdents_empty:
	xor %rax, %rax
	jmp std_getdents_epilogue
std_getdents_syserr:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
std_getdents_epilogue:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov -40(%rbp), %r15
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_stat
std_stat:
	# SYS_stat64 → remap mode/size into Linux-shaped Tu Stat (no $INODE64 symbol).
	push %rbp
	mov %rsp, %rbp
	push %rbx
	mov %rsi, %rbx
	sub $160, %rsp
	mov %rsp, %rsi
	mov $0x2000152, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_stat_err
	# Darwin mode @4 (u16); Tu st_mode @24
	mov %rsp, %rsi
	add $4, %rsi
	xor %rcx, %rcx
	movb (%rsi), %cl
	xor %rax, %rax
	add $1, %rsi
	movb (%rsi), %al
	shl $8, %rax
	or %rax, %rcx
	mov %rbx, %rdi
	add $24, %rdi
	mov %rcx, %rax
	movb %al, (%rdi)
	shr $8, %rax
	add $1, %rdi
	movb %al, (%rdi)
	add $1, %rdi
	movb $0, (%rdi)
	add $1, %rdi
	movb $0, (%rdi)
	# Darwin size @96; Tu st_size @48
	mov %rsp, %rsi
	add $96, %rsi
	mov (%rsi), %rax
	mov %rbx, %rdi
	add $48, %rdi
	mov %rax, (%rdi)
	xor %rax, %rax
	add $160, %rsp
	pop %rbx
	pop %rbp
	retq
std_stat_err:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	add $160, %rsp
	pop %rbx
	pop %rbp
	retq

.globl std_fstat
std_fstat:
	mov $0x20000BD, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.globl std_lstat
std_lstat:
	mov $0x20000BE, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.globl std_execve
std_execve:
	# Prefer libSystem execve for Mach/dyld consistency after fork.
	push %rbp
	mov %rsp, %rbp
	call _execve
	pop %rbp
	# On success does not return; on failure return -1.
	mov $-1, %rax
	retq

.globl std_time
std_time:
	# gettimeofday(tp, tz) — SYS 116; return tv_sec in rax like Linux time(2)
	sub $16, %rsp
	mov %rsp, %rdi
	xor %rsi, %rsi
	mov $0x2000074, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_time_err
	mov (%rsp), %rax
	add $16, %rsp
	retq
std_time_err:
	add $16, %rsp
	jmp std_errno_neg

.globl std_clock_gettime
std_clock_gettime:
	# Approximate: ignore clockid, fill timespec via gettimeofday
	push %rsi
	sub $16, %rsp
	mov %rsp, %rdi
	xor %rsi, %rsi
	mov $0x2000074, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_clock_err
	mov (%rsp), %rax
	mov 8(%rsp), %rdx
	add $16, %rsp
	pop %rsi
	mov %rax, (%rsi)
	# usec → nsec: n*1000 = n*1024 - n*16 - n*8
	mov %rdx, %rax
	shl $10, %rax
	mov %rdx, %rcx
	shl $4, %rcx
	sub %rcx, %rax
	mov %rdx, %rcx
	shl $3, %rcx
	sub %rcx, %rax
	mov %rax, 8(%rsi)
	xor %rax, %rax
	retq
std_clock_err:
	add $16, %rsp
	pop %rsi
	jmp std_errno_neg

.globl std_sigreturn
std_sigreturn:
	# SYS_sigreturn 184; normally reached from std_sigtramp with
	# rdi=uctx, rsi=UC_FLAVOR(30), rdx=token (syscall ABI via r10 for 4th).
	mov %rcx, %r10
	mov $0x20000B8, %rax
	syscall
	# Returning is fatal — spin (asmer has no ud2).
std_sigreturn_dead:
	jmp std_sigreturn_dead

.globl std_sigreturn_pc
std_sigreturn_pc:
	lea std_sigreturn(%rip), %rax
	retq

# Darwin kernel trampoline ABI (matches libplatform x86_64 _sigtramp):
#   rdi=handler, rsi=sigstyle, rdx=sig, rcx=sinfo, r8=uctx, r9=token
# Call handler(sig, sinfo, uctx) then sigreturn(uctx, UC_FLAVOR, token).
.globl std_sigtramp
std_sigtramp:
	push %rbp
	mov %rsp, %rbp
	mov %rdi, %rax
	mov %r8, %rbx
	mov %r9, %r12
	mov %edx, %edi
	mov %rcx, %rsi
	mov %r8, %rdx
	call *%rax
	mov %rbx, %rdi
	mov $30, %esi
	mov %r12, %rdx
	mov $0x20000B8, %rax
	syscall
std_sigtramp_dead:
	jmp std_sigtramp_dead

.globl std_sigtramp_pc
std_sigtramp_pc:
	lea std_sigtramp(%rip), %rax
	retq

# Translate Linux-layout Sigactiont* (from os.setsignal) into Darwin
# struct __sigaction and issue SYS_sigaction (46). Inject std_sigtramp.
# rdi=sig, rsi=act, rdx=oact, rcx=mask_size (ignored).
.globl std_rt_sigaction
std_rt_sigaction:
	cmp $0, %rsi
	je std_rt_sigaction_null
	sub $32, %rsp
	mov 0(%rsi), %rax
	mov %rax, 0(%rsp)
	lea std_sigtramp(%rip), %rax
	mov %rax, 8(%rsp)
	movl $0xffffffff, 16(%rsp)
	# SA_SIGINFO|SA_RESTART (Darwin): 0x40|0x2
	movl $0x42, 20(%rsp)
	mov %rsp, %rsi
	xor %rdx, %rdx
	mov $0x200002E, %rax
	syscall
	setb %cl
	add $32, %rsp
	cmp $0, %cl
	jne std_errno_neg
	retq
std_rt_sigaction_null:
	xor %rax, %rax
	retq

.globl std_mmap
std_mmap:
	# SYS_mmap 197; 4th arg already in rcx → r10 for syscall ABI.
	# Remap Linux MAP_ANON (0x20) → Darwin MAP_ANON (0x1000); avoid asmer `or`.
	mov %rcx, %rax
	and $0x20, %rax
	cmp $0, %rax
	je std_mmap_flags_ok
	sub $0x20, %rcx
	add $0x1000, %rcx
std_mmap_flags_ok:
	mov %rcx, %r10
	mov $0x20000C5, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.globl std_madvise
std_madvise:
	mov $0x200004B, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.globl std_munmap
std_munmap:
	mov $0x2000049, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
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
	mov $0x200003A, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.global std_cputicks
std_cputicks:
	rdtscp
	shl $0x20, %rdx
	add %rdx, %rax
	retq

.globl std_gettid
std_gettid:
	# thread_selfid = 372
	mov $0x2000174, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

# Darwin has no signalfd(2). Emulate with a dedicated kqueue + EVFILT_SIGNAL
# plus an empty catcher (prevents default terminate). Drain reads via sys_read
# which harvests kevents into a Linux signalfd_siginfo-shaped buffer.
.data
.align 8
.globl darwin_sfd_kq
darwin_sfd_kq:
	.quad 0
darwin_sfd_mask:
	.quad 0
.globl darwin_sig_mask
darwin_sig_mask:
	.quad 0

.text
.globl std_sfd_handler
std_sfd_handler:
	retq

.globl std_signalfd4
std_signalfd4:
	# rdi=fd (-1 create), rsi=mask ptr, rdx=sizemask, rcx=flags
	# Create kqueue; on mask updates EV_ADD EVFILT_SIGNAL. Signals are
	# blocked via std_rt_sigprocmask (soft+real) so default actions do not run.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $64, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	cmp $-1, %ebx
	jne std_signalfd4_update
	mov $0x200016A, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_signalfd4_kq_err
	mov %rax, %rbx
	mov %rax, darwin_sfd_kq(%rip)
	jmp std_signalfd4_update
std_signalfd4_kq_err:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	jmp std_signalfd4_done
std_signalfd4_update:
	cmp $0, %r12
	je std_signalfd4_ret_fd
	mov %r12, %rsi
	mov 0(%rsi), %rax
	mov %rax, %r12
	mov darwin_sfd_mask(%rip), %r13
	# signum in r15 (1..32); Darwin sigset_t is 4 bytes.
	mov $1, %r15
std_signalfd4_loop:
	cmp $32, %r15
	jg std_signalfd4_mask_done
	# bit = 1 << (signum-1) via shl %cl
	mov %r15, %rcx
	sub $1, %rcx
	mov $1, %rax
	shl %cl, %rax
	mov %r12, %rdx
	and %rax, %rdx
	mov %r13, %rsi
	and %rax, %rsi
	cmp %rdx, %rsi
	je std_signalfd4_next
	cmp $0, %rdx
	je std_signalfd4_clr
	# EV_ADD|EV_CLEAR EVFILT_SIGNAL — save signum at -48(%rbp)
	mov %r15, -48(%rbp)
	mov darwin_sfd_kq(%rip), %rdi
	sub $32, %rsp
	mov %r15, 0(%rsp)
	movw $-6, 8(%rsp)
	movw $0x21, 10(%rsp)
	movl $0, 12(%rsp)
	movq $0, 16(%rsp)
	movq $0, 24(%rsp)
	mov %rsp, %rsi
	mov $1, %edx
	xor %rcx, %rcx
	xor %r8, %r8
	xor %r9, %r9
	mov %rcx, %r10
	mov $0x200016B, %rax
	syscall
	add $32, %rsp
	mov -48(%rbp), %r15
	jmp std_signalfd4_next
std_signalfd4_clr:
	mov %r15, -48(%rbp)
	mov darwin_sfd_kq(%rip), %rdi
	sub $32, %rsp
	mov %r15, 0(%rsp)
	movw $-6, 8(%rsp)
	movw $0x2, 10(%rsp)
	movl $0, 12(%rsp)
	movq $0, 16(%rsp)
	movq $0, 24(%rsp)
	mov %rsp, %rsi
	mov $1, %edx
	xor %rcx, %rcx
	xor %r8, %r8
	xor %r9, %r9
	mov %rcx, %r10
	mov $0x200016B, %rax
	syscall
	add $32, %rsp
	mov -48(%rbp), %r15
std_signalfd4_next:
	add $1, %r15
	jmp std_signalfd4_loop
std_signalfd4_mask_done:
	mov %r12, darwin_sfd_mask(%rip)
std_signalfd4_ret_fd:
	mov %rbx, %rax
std_signalfd4_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov -40(%rbp), %r15
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_rt_sigprocmask
std_rt_sigprocmask:
	# Soft mask (for signalfd4) + real _sigprocmask so EVFILT_SIGNAL can
	# observe blocked signals without default terminate.
	# rdi=how (Linux: 0/1/2), rsi=set, rdx=oldset, rcx=size
	# Darwin how is 1/2/3 — remap before _sigprocmask.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %r14
	mov darwin_sig_mask(%rip), %rax
	cmp $0, %r14
	je std_rt_sigprocmask_no_old
	mov %rax, 0(%r14)
std_rt_sigprocmask_no_old:
	cmp $0, %r13
	je std_rt_sigprocmask_kern
	mov 0(%r13), %rbx
	mov %r12, %rcx
	# Keep how in low 32 bits (avoid $0xffffffff — asmer folds it to -1).
	mov %ecx, %ecx
	cmp $0, %rcx
	je std_rt_sigprocmask_block
	cmp $1, %rcx
	je std_rt_sigprocmask_unblock
	# SETMASK (Linux how=2)
	mov %rbx, darwin_sig_mask(%rip)
	jmp std_rt_sigprocmask_kern
std_rt_sigprocmask_block:
	or %rbx, %rax
	mov %rax, darwin_sig_mask(%rip)
	jmp std_rt_sigprocmask_kern
std_rt_sigprocmask_unblock:
	mov darwin_sig_mask(%rip), %rax
	mov $-1, %rcx
	xor %rbx, %rcx
	and %rcx, %rax
	mov %rax, darwin_sig_mask(%rip)
std_rt_sigprocmask_kern:
	# Remap Linux how → Darwin: 0→1, 1→2, 2→3
	mov %r12, %rax
	mov %eax, %eax
	add $1, %rax
	mov %rax, %rdi
	mov %r13, %rsi
	xor %rdx, %rdx
	call _sigprocmask
	cmp $-1, %rax
	jne std_rt_sigprocmask_ok
	call ___error
	mov (%rax), %edi
	xor %rax, %rax
	sub %rdi, %rax
	jmp std_rt_sigprocmask_done
std_rt_sigprocmask_ok:
	xor %rax, %rax
std_rt_sigprocmask_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_pidfd_open
std_pidfd_open:
	mov $-78, %rax
	retq

.globl std_wait4
std_wait4:
	# Darwin wait4 syscall; args already SysV in rdi/rsi/rdx/rcx.
	# rcx → r10 for syscall ABI.
	mov %rcx, %r10
	mov $0x2000007, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_errno_neg
	retq

.globl std_fork
std_fork:
	# Darwin SYS_fork (Libc __fork.s): both sides get child pid in %rax;
	# %edx==0 → parent, %edx!=0 → child (then return 0). Linux stub unchanged.
	mov $0x2000002, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne std_fork_err
	# asmer: no `or`/`test`/`jz`; zero-extend edx via mov then cmp.
	mov %edx, %ecx
	cmp $0, %ecx
	je std_fork_is_parent
	xor %rax, %rax
std_fork_is_parent:
	retq
std_fork_err:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	retq

.globl std_dup2
std_dup2:
	# libSystem dup2(oldfd, newfd).
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _dup2
	cmp $-1, %rax
	jne std_dup2_ok
	call ___error
	mov (%rax), %edi
	xor %rax, %rax
	sub %rdi, %rax
std_dup2_ok:
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_pipe2
std_pipe2:
	# pipe(2) + fcntl for Linux O_CLOEXEC (0x80000) / O_NONBLOCK (0x800).
	# rdi = int fds[2], rsi = flags
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	mov %rbx, %rdi
	call _pipe
	cmp $-1, %rax
	jne std_pipe2_ok_pipe
	call ___error
	mov (%rax), %edi
	xor %rax, %rax
	sub %rdi, %rax
	jmp std_pipe2_done
std_pipe2_ok_pipe:
	xor %r13, %r13
std_pipe2_flag_loop:
	cmp $2, %r13
	jge std_pipe2_ret0
	mov %r13, %rax
	add %rax, %rax
	add %rax, %rax
	add %rbx, %rax
	movl (%rax), %edi
	mov %r12, %rax
	and $0x800, %eax
	cmp $0, %eax
	je std_pipe2_ce
	mov $4, %esi
	mov $4, %edx
	call _fcntl
std_pipe2_ce:
	mov %r13, %rax
	add %rax, %rax
	add %rax, %rax
	add %rbx, %rax
	movl (%rax), %edi
	mov %r12, %rax
	and $0x80000, %eax
	cmp $0, %eax
	je std_pipe2_next
	mov $2, %esi
	mov $1, %edx
	call _fcntl
std_pipe2_next:
	add $1, %r13
	jmp std_pipe2_flag_loop
std_pipe2_ret0:
	xor %rax, %rax
std_pipe2_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov %rbp, %rsp
	pop %rbp
	retq

# Shared: rax=errno, CF path → return -errno
std_errno_neg:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	retq
