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
	# Unix tests use /tmp/...; map to drive:\tmp for CreateFileA/CreateDirectoryA.
	lea win_tmp_path(%rip), %rcx
	xor %edx, %edx
	call CreateDirectoryA
	mov %rbp, %rsp
	pop %rbp
	ret

# SysV: rdi=path. Returns 0 or negative errno-style.
.globl std_mkdir
std_mkdir:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	xor %edx, %edx
	call CreateDirectoryA
	cmp $0, %eax
	jne smk_ok
	call GetLastError
	cmp $183, %eax
	je smk_ok
	mov $-1, %rax
	jmp smk_out
smk_ok:
	xor %eax, %eax
smk_out:
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_rmdir
std_rmdir:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call RemoveDirectoryA
	cmp $0, %eax
	jne srm_ok
	mov $-1, %rax
	jmp srm_out
srm_ok:
	xor %eax, %eax
srm_out:
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_unlink
std_unlink:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call DeleteFileA
	cmp $0, %eax
	jne sun_ok
	mov $-1, %rax
	jmp sun_out
sun_ok:
	xor %eax, %eax
sun_out:
	mov %rbp, %rsp
	pop %rbp
	retq

.globl win_fd_get
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

.globl win_fd_alloc
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

# Mark fd as Winsock SOCKET (closesocket on close). rdi=fd
.globl win_fd_mark_sock
win_fd_mark_sock:
	cmp $0, %rdi
	jl wms_out
	cmp $256, %rdi
	jge wms_out
	lea win_fd_sock(%rip), %rax
	add %rdi, %rax
	movb $1, (%rax)
wms_out:
	ret

# Clear sock mark. rdi=fd
win_fd_clear_sock:
	cmp $0, %rdi
	jl wcs_out
	cmp $256, %rdi
	jge wcs_out
	lea win_fd_sock(%rip), %rax
	add %rdi, %rax
	movb $0, (%rax)
wcs_out:
	ret

# Return 1 if sock. rdi=fd
.globl win_fd_is_sock
win_fd_is_sock:
	xor %eax, %eax
	cmp $0, %rdi
	jl wis_out
	cmp $256, %rdi
	jge wis_out
	lea win_fd_sock(%rip), %rax
	add %rdi, %rax
	movzbl (%rax), %eax
wis_out:
	ret

# Map tu epoll fd → ep_idx (0..15), or 0xFF if not epoll.
win_ep_map_ensure:
	# Init sentinel at fd_of[255]=0xFE (tu fds are 0..254). Avoids peff AV on a
	# separate .long ready flag and survives store of ep_idx+1 into other slots.
	lea win_ep_fd_of(%rip), %rax
	add $255, %rax
	movzbl (%rax), %eax
	cmp $0xFE, %eax
	je weme_ok
	xor %ecx, %ecx
weme_fill:
	lea win_ep_fd_of(%rip), %rax
	add %rcx, %rax
	movb $0xFF, (%rax)
	add $1, %ecx
	cmp $256, %ecx
	jl weme_fill
	lea win_ep_fd_of(%rip), %rax
	add $255, %rax
	movb $0xFE, (%rax)
weme_ok:
	ret

.globl win_ep_set_fd
win_ep_set_fd:
	# rdi=tu_fd rsi=ep_idx. Store ep_idx+1 so 0 means "not epoll".
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	mov %rdi, %rbx
	mov %rsi, %r12
	call win_ep_map_ensure
	cmp $0, %rbx
	jl wes_out
	cmp $256, %rbx
	jge wes_out
	lea win_ep_fd_of(%rip), %rax
	add %rbx, %rax
	mov %r12, %rdx
	add $1, %rdx
	movb %dl, (%rax)
wes_out:
	pop %r12
	pop %rbx
	pop %rbp
	ret

.globl win_ep_get_fd
win_ep_get_fd:
	# rdi=tu_fd → eax=ep_idx or 0xFF
	push %rbp
	mov %rsp, %rbp
	push %rbx
	mov %rdi, %rbx
	call win_ep_map_ensure
	mov $0xFF, %eax
	cmp $0, %rbx
	jl weg_out
	cmp $256, %rbx
	jge weg_out
	lea win_ep_fd_of(%rip), %rax
	add %rbx, %rax
	movzbl (%rax), %eax
	cmp $0, %eax
	je weg_none
	sub $1, %eax
	jmp weg_out
weg_none:
	mov $0xFF, %eax
weg_out:
	pop %rbx
	pop %rbp
	ret

.globl win_ep_clear_fd
win_ep_clear_fd:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	mov %rdi, %rbx
	call win_ep_map_ensure
	cmp $0, %rbx
	jl wec_out
	cmp $256, %rbx
	jge wec_out
	lea win_ep_fd_of(%rip), %rax
	add %rbx, %rax
	movb $0, (%rax)
wec_out:
	pop %rbx
	pop %rbp
	ret

# Clear win_fds[tu_fd] slot. rdi=fd
.globl win_fd_slot_clear
win_fd_slot_clear:
	cmp $0, %rdi
	jl wfsc_out
	cmp $256, %rdi
	jge wfsc_out
	shl $3, %rdi
	lea win_fds(%rip), %rax
	add %rdi, %rax
	movq $0, (%rax)
wfsc_out:
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
	mov %rbx, %rax
	and $3, %rax
	cmp $1, %rax
	je so_w
	cmp $2, %rax
	je so_rw
	mov $0x80000000, %rdx
	jmp so_acc
so_w:
	mov $0x40000000, %rdx
	jmp so_acc
so_rw:
	mov $0xC0000000, %rdx
so_acc:
	mov %rdx, 56(%rsp)
	# Creation disposition from O_CREAT(64) / O_TRUNC(512).
	# Reload flags each time — do not reuse a clobbered and-mask.
	mov $3, %eax
	mov %rbx, %rcx
	and $64, %rcx
	cmp $0, %rcx
	je so_trunc_only
	mov %rbx, %rcx
	and $512, %rcx
	cmp $0, %rcx
	je so_creat
	mov $2, %eax
	jmp so_disp_store
so_creat:
	mov $4, %eax
	jmp so_disp_store
so_trunc_only:
	mov %rbx, %rcx
	and $512, %rcx
	cmp $0, %rcx
	je so_disp_store
	mov $5, %eax
so_disp_store:
	mov %eax, 32(%rsp)
so_call:
	mov $128, %eax
	mov %eax, 40(%rsp)
	movq $0, 48(%rsp)
	mov %r12, %rcx
	# Reload access — do not rely on edx surviving the disposition block.
	mov 56(%rsp), %rdx
	mov $7, %r8
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
	call GetLastError
	mov %eax, %ecx
	xor %eax, %eax
	sub %rcx, %rax
	jmp so_out
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
	push %r12
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rbx
	cmp $3, %rbx
	jl sc_ok0
	mov %rbx, %rdi
	call win_fd_get
	cmp $0, %rax
	je sc_err
	mov %rax, %r12
	mov %rbx, %rdi
	call win_fd_is_sock
	cmp $0, %eax
	je sc_file
	mov %r12, %rcx
	call closesocket
	jmp sc_cleared
sc_file:
	mov %r12, %rcx
	call CloseHandle
sc_cleared:
	mov %rbx, %rdi
	call win_fd_clear_sock
	mov %rbx, %rdi
	call win_ep_clear_fd
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
	lea -16(%rbp), %rsp
	pop %r12
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
win_fd_sock:
	.zero 256
win_ep_fd_of:
	.zero 256
win_brk_base:
	.quad 0
win_brk_pos:
	.quad 0
win_brk_limit:
	.quad 0
win_unix_epoch:
	.quad 116444736000000000
win_tmp_path:
	.string "/tmp"
