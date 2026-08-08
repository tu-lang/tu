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
	call _close
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
	# getdirentries64 + convert to dir.tu layout (name@18, type@reclen-1).
	# Memory ops via %rax/%rsi/%rdi only — asmer breaks movb N(%rN).
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rdi, %r15
	sub $0x1010, %rsp
	mov %rsp, %r14
	mov $0, %rax
	mov %r14, %rdi
	add $0x1000, %rdi
	mov %rax, (%rdi)
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
	mov 16(%rax), %rcx
	mov %rcx, %rdx
	and $0xffff, %rcx
	shr $16, %rdx
	and $0xffff, %rdx
	cmp $0, %rcx
	je std_getdents_done
	mov %rax, %rsi
	add $20, %rsi
	movb (%rsi), %al
	mov %r14, %rdi
	add $0x1008, %rdi
	movb %al, (%rdi)
	mov %r14, %rax
	add %rbx, %rax
	mov %rdx, %r8
	add $19, %r8
	add $7, %r8
	shr $3, %r8
	shl $3, %r8
	mov %r11, %r9
	add %r8, %r9
	cmp %r13, %r9
	jg std_getdents_done
	mov %r12, %rdi
	add %r11, %rdi
	mov (%rax), %rsi
	mov %rsi, (%rdi)
	mov 8(%rax), %rsi
	mov %rsi, 8(%rdi)
	mov %rdi, %rsi
	add $16, %rsi
	mov %r8, %rax
	movb %al, (%rsi)
	shr $8, %rax
	add $1, %rsi
	movb %al, (%rsi)
	mov %r14, %rax
	add %rbx, %rax
	mov %rax, %rsi
	add $21, %rsi
	mov %rdi, %rax
	add $18, %rax
	mov %rdi, %r9
std_getdents_cpy:
	cmp $0, %rdx
	je std_getdents_cpy_done
	movb (%rsi), %cl
	movb %cl, (%rax)
	add $1, %rsi
	add $1, %rax
	sub $1, %rdx
	jmp std_getdents_cpy
std_getdents_cpy_done:
	movb $0, (%rax)
	mov %r9, %rax
	add %r8, %rax
	sub $1, %rax
	mov %r14, %rsi
	add $0x1008, %rsi
	movb (%rsi), %cl
	movb %cl, (%rax)
	mov %r14, %rax
	add %rbx, %rax
	mov 16(%rax), %rcx
	and $0xffff, %rcx
	add %r8, %r11
	add %rcx, %rbx
	jmp std_getdents_loop
std_getdents_done:
	mov %r11, %rax
	add $0x1010, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq
std_getdents_empty:
	xor %rax, %rax
	add $0x1010, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq
std_getdents_syserr:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	add $0x1010, %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
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

.globl std_signalfd4
std_signalfd4:
	mov $-78, %rax
	retq

.globl std_rt_sigprocmask
std_rt_sigprocmask:
	xor %rax, %rax
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
	# Darwin has dup2 as libc; use fcntl F_DUPFD if needed — stub via raw 90? use openat path
	# SYS_dup2 not present; approximate with return -78
	mov $-78, %rax
	retq

.globl std_pipe2
std_pipe2:
	mov $-78, %rax
	retq

# Shared: rax=errno, CF path → return -errno
std_errno_neg:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	retq
