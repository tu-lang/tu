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
	# SysV rdi=fd → Tu stack ABI: push table, push fd.
	# Tu callee cleans args (do not add %rsp after call).
	lea win_fds(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_get_tu
	ret

.globl win_fd_alloc
win_fd_alloc:
	lea win_fds(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_alloc_tu
	movsxd %eax, %rax
	ret

.globl win_fd_mark_sock
win_fd_mark_sock:
	lea win_fd_sock(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_mark_sock_tu
	ret

win_fd_clear_sock:
	lea win_fd_sock(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_clear_sock_tu
	ret

.globl win_fd_is_sock
win_fd_is_sock:
	lea win_fd_sock(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_is_sock_tu
	movsxd %eax, %rax
	ret

# Clear win_fds[tu_fd] via Tu (also used from close path).
.globl win_fd_slot_clear
win_fd_slot_clear:
	lea win_fds(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_fd_slot_clear_tu
	ret

win_ep_map_ensure:
	lea win_ep_fd_of(%rip), %rax
	push %rax
	call runtime_win_ep_map_ensure_tu
	ret

.globl win_ep_set_fd
win_ep_set_fd:
	# rdi=tu_fd rsi=ep_idx
	lea win_ep_fd_of(%rip), %rax
	push %rax
	push %rsi
	push %rdi
	call runtime_win_ep_set_fd_tu
	ret

.globl win_ep_get_fd
win_ep_get_fd:
	lea win_ep_fd_of(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_ep_get_fd_tu
	movsxd %eax, %rax
	ret

.globl win_ep_clear_fd
win_ep_clear_fd:
	# Map clear only; callers that free a software-epoll set call
	# win_ep_release_idx first (see std_close epoll path).
	lea win_ep_fd_of(%rip), %rax
	push %rax
	push %rdi
	call runtime_win_ep_clear_fd_tu
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
	# O_DIRECTORY (65536): open dir handle for getdents/opendir.
	mov $128, %eax
	mov %rbx, %rcx
	and $65536, %rcx
	cmp $0, %rcx
	je so_flags_store
	mov $0x02000080, %eax
so_flags_store:
	mov %eax, 40(%rsp)
so_call:
	movq $0, 48(%rsp)
	mov %r12, %rcx
	# Reload access — do not rely on edx surviving the disposition block.
	mov 56(%rsp), %rdx
	mov $7, %r8
	xor %r9, %r9
	# Keep flags across win_fd_alloc (Tu may clobber rbx).
	mov %rbx, 64(%rsp)
	call CreateFileA
	cmp $-1, %rax
	je so_err
	mov %rax, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je so_err
	movsxd %eax, %rax
	# If O_DIRECTORY, remember path for getdents (FindFirstFile needs a path).
	mov 64(%rsp), %rcx
	and $65536, %rcx
	cmp $0, %rcx
	je so_out
	# rax=fd; copy cstring at r12 into win_dir_path[fd]
	push %rax
	lea win_dir_path(%rip), %rdi
	mov %rax, %rcx
	shl $8, %rcx
	add %rcx, %rdi
	mov %r12, %rsi
	mov $255, %edx
so_pcpy:
	cmp $0, %edx
	je so_pcpy_done
	movb (%rsi), %cl
	movb %cl, (%rdi)
	cmp $0, %cl
	je so_pcpy_done
	add $1, %rsi
	add $1, %rdi
	sub $1, %edx
	jmp so_pcpy
so_pcpy_done:
	movb $0, (%rdi)
	pop %rax
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
	# Software epoll tu-fd: no OS handle (slot holds sentinel 1). Free set only.
	mov %rbx, %rdi
	call win_ep_get_fd
	cmp $0xFF, %eax
	je sc_normal
	mov %eax, %r12d
	mov %r12, %rdi
	call win_ep_release_idx
	mov %rbx, %rdi
	call win_ep_clear_fd
	mov %rbx, %rdi
	shl $3, %rdi
	lea win_fds(%rip), %rax
	add %rdi, %rax
	movq $0, (%rax)
	jmp sc_ok0
sc_normal:
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
	# Drop listen mark + any accept stash for this tu fd.
	cmp $0, %rbx
	jl sc_fdslot
	cmp $256, %rbx
	jge sc_fdslot
	lea win_fd_listen(%rip), %rax
	add %rbx, %rax
	movb $0, (%rax)
	lea win_accept_stash(%rip), %rax
	mov %rbx, %rcx
	shl $3, %rcx
	add %rcx, %rax
	mov (%rax), %rcx
	movq $0, (%rax)
	cmp $0, %rcx
	je sc_fdslot
	# closesocket stashed peer (Win64 rcx)
	sub $32, %rsp
	call closesocket
	add $32, %rsp
sc_fdslot:
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
	# Directory listing for the driver uses os.win_find_* (path-based).
	# Keep ENOSYS here until a full HANDLE-based getdents lands.
	mov $-38, %rax
	retq

.globl std_stat
std_stat:
	# SysV: rdi=path, rsi=Stat*. Fill st_mode (S_IFDIR/S_IFREG) via GetFileAttributesA.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov %rsi, %rbx
	mov %rdi, %rcx
	call GetFileAttributesA
	cmp $-1, %eax
	je sst_err
	movq $0, (%rbx)
	movq $0, 8(%rbx)
	movq $0, 16(%rbx)
	mov %eax, %edx
	and $0x10, %edx
	cmp $0, %edx
	je sst_reg
	movl $16384, 24(%rbx)
	jmp sst_ok
sst_reg:
	movl $32768, 24(%rbx)
sst_ok:
	xor %eax, %eax
	jmp sst_out
sst_err:
	mov $-2, %rax
sst_out:
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.globl std_fstat
std_fstat:
	mov $-38, %rax
	retq

.globl std_lstat
std_lstat:
	jmp std_stat

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

# SysV no-body APIs for runtime/pipe.tu (registercall).
# CreatePipe(PHANDLE, PHANDLE, NULL, 0)
.global runtime_win_api_create_pipe
runtime_win_api_create_pipe:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	mov %rsi, %rdx
	xor %r8, %r8
	xor %r9, %r9
	call CreatePipe
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_set_handle_info
runtime_win_api_set_handle_info:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdx, %r8
	mov %rsi, %rdx
	mov %rdi, %rcx
	call SetHandleInformation
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_pipe_nowait
runtime_win_api_pipe_nowait:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $48, %rsp
	mov $1, %eax
	mov %eax, 32(%rsp)
	mov %rdi, %rcx
	lea 32(%rsp), %rdx
	xor %r8, %r8
	xor %r9, %r9
	call SetNamedPipeHandleState
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_close_handle
runtime_win_api_close_handle:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call CloseHandle
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.globl std_pipe2
std_pipe2:
	# SysV rdi=fds* rsi=flags. Tu stack ABI, callee cleans.
	lea win_fds(%rip), %rax
	push %rax
	push %rsi
	push %rdi
	call runtime_win_pipe2_tu
	retq

.data
.align 8
.globl win_fds
win_fds:
	.zero 2048
.globl win_fd_sock
win_fd_sock:
	.zero 256
.globl win_ep_fd_of
win_ep_fd_of:
	.zero 256
win_find_h:
	.zero 2048
win_dir_path:
	.zero 65536
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
