# Darwin stubs for library/sys — keep symbol surface; ENOSYS (-78) where absent.
# Enough for link; networking/epoll not in Phase 3a smoke.
.text
.global sys_socket
sys_socket:
	# libSystem socket — raw syscall leaves protocol/ABI footguns with Tu calls.
	push %rbp
	mov %rsp, %rbp
	call _socket
	pop %rbp
	# libc returns -1 on error; map to negative errno-ish for Tu checks (fd<0).
	cmp $-1, %rax
	jne sys_socket_ok
	mov $-1, %rax
sys_socket_ok:
	retq

.global sys_bind
sys_bind:
	mov $0x2000068, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_connect
sys_connect:
	mov $0x2000062, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_listen
sys_listen:
	mov $0x200006A, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_accept4
sys_accept4:
	# accept = 30; ignore flags
	mov $0x200001E, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_eventfd
sys_eventfd:
	mov $-78, %rax
	retq

.global sys_send
sys_send:
	mov %rcx, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $0x2000085, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_sendto
sys_sendto:
	mov %rcx, %r10
	mov $0x2000085, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_recv
sys_recv:
	mov %rcx, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $0x200001D, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_recvfrom
sys_recvfrom:
	mov %rcx, %r10
	mov $0x200001D, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_shutdown
sys_shutdown:
	mov $0x2000086, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_setsockopt
sys_setsockopt:
	mov %rcx, %r10
	mov $0x2000069, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_getsockopt
sys_getsockopt:
	# Translate Linux SOL_SOCKET/SO_* into Darwin values for shared library/sys.
	# Linux SOL_SOCKET=1 → Darwin 0xffff; SO_ERROR=4 → 0x1007.
	push %rbp
	mov %rsp, %rbp
	cmp $1, %esi
	jne sys_getsockopt_level_ok
	mov $0xffff, %esi
sys_getsockopt_level_ok:
	cmp $4, %edx
	jne sys_getsockopt_opt_ok
	cmp $0xffff, %esi
	jne sys_getsockopt_opt_ok
	mov $0x1007, %edx
sys_getsockopt_opt_ok:
	# Tu: rdi=fd rsi=level rdx=optname rcx=optval r8=optlen*
	# libc: same SysV; optlen is socklen_t*.
	mov %r8, %r8
	call _getsockopt
	pop %rbp
	cmp $-1, %rax
	jne sys_getsockopt_ok
	mov $-22, %rax
sys_getsockopt_ok:
	retq

.global sys_getaddrinfo
sys_getaddrinfo:
	mov $-4, %rax
	retq

.global sys_fcntl
sys_fcntl:
	# F_SETFL=4: remap Linux O_NONBLOCK(2048) → Darwin(4).
	cmp $4, %esi
	jne sys_fcntl_call
	mov %edx, %eax
	and $2048, %eax
	cmp $0, %eax
	je sys_fcntl_call
	sub $2048, %edx
	add $4, %edx
sys_fcntl_call:
	push %rbp
	mov %rsp, %rbp
	call _fcntl
	pop %rbp
	cmp $-1, %rax
	jne sys_fcntl_ok
	mov $-22, %rax
sys_fcntl_ok:
	retq

.global sys_read
sys_read:
	# libSystem — raw write/read syscall returns EINVAL in this Mach-O link path.
	push %rbp
	mov %rsp, %rbp
	call _read
	pop %rbp
	cmp $-1, %rax
	jne sys_read_ok
	mov $-22, %rax
sys_read_ok:
	retq

.global sys_write
sys_write:
	push %rbp
	mov %rsp, %rbp
	call _write
	pop %rbp
	cmp $-1, %rax
	jne sys_write_ok
	mov $-22, %rax
sys_write_ok:
	retq

.global sys_close
sys_close:
	push %rbp
	mov %rsp, %rbp
	call _close
	pop %rbp
	cmp $-1, %rax
	jne sys_close_ok
	mov $-22, %rax
sys_close_ok:
	retq

.global sys_socketpair
sys_socketpair:
	mov %rcx, %r10
	mov $0x2000087, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_epoll_create1
sys_epoll_create1:
	mov $-78, %rax
	retq

.global sys_epoll_ctl
sys_epoll_ctl:
	mov $-78, %rax
	retq

.global sys_epoll_wait
sys_epoll_wait:
	mov $-78, %rax
	retq

.global sys_readlink
sys_readlink:
	mov $0x200003A, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_rename
sys_rename:
	mov $0x2000080, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_link
sys_link:
	mov $0x2000009, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_symlink
sys_symlink:
	mov $0x2000039, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_openat
sys_openat:
	# Linux AT_FDCWD=-100; Darwin AT_FDCWD=-2.
	cmp $-100, %edi
	jne sys_openat_dirfd_ok
	mov $-2, %edi
sys_openat_dirfd_ok:
	# Remap Linux open flags → Darwin (add bits; asmer or/%rNNd weak).
	push %rbx
	mov %rdx, %rbx
	mov %ebx, %edx
	and $3, %edx
	mov %ebx, %eax
	and $64, %eax
	cmp $0, %eax
	je sys_openat_nocreat
	add $512, %edx
sys_openat_nocreat:
	mov %ebx, %eax
	and $512, %eax
	cmp $0, %eax
	je sys_openat_notrunc
	add $1024, %edx
sys_openat_notrunc:
	mov %ebx, %eax
	and $1024, %eax
	cmp $0, %eax
	je sys_openat_noappend
	add $8, %edx
sys_openat_noappend:
	mov %ebx, %eax
	and $2048, %eax
	cmp $0, %eax
	je sys_openat_nonblock_done
	add $4, %edx
sys_openat_nonblock_done:
	mov %ebx, %eax
	and $524288, %eax
	cmp $0, %eax
	je sys_openat_nocloexec
	add $16777216, %edx
sys_openat_nocloexec:
	pop %rbx
	# libc openat uses SysV rcx=mode (not r10).
	push %rbp
	mov %rsp, %rbp
	call _openat
	pop %rbp
	cmp $-1, %rax
	jne sys_openat_ok
	mov $-22, %rax
sys_openat_ok:
	retq

.global sys_mkdir
sys_mkdir:
	push %rbp
	mov %rsp, %rbp
	call _mkdir
	pop %rbp
	cmp $-1, %rax
	jne sys_mkdir_ok
	mov $-22, %rax
sys_mkdir_ok:
	retq

.global sys_rmdir
sys_rmdir:
	push %rbp
	mov %rsp, %rbp
	call _rmdir
	pop %rbp
	cmp $-1, %rax
	jne sys_rmdir_ok
	mov $-22, %rax
sys_rmdir_ok:
	retq

.global sys_unlink
sys_unlink:
	push %rbp
	mov %rsp, %rbp
	call _unlink
	pop %rbp
	cmp $-1, %rax
	jne sys_unlink_ok
	mov $-22, %rax
sys_unlink_ok:
	retq

.global sys_chmod
sys_chmod:
	mov $0x200000F, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_stat
sys_stat:
	mov $0x20000BC, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_fstat
sys_fstat:
	mov $0x20000BD, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_lstat
sys_lstat:
	mov $0x20000BE, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_lseek
sys_lseek:
	mov $0x20000C7, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_fsync
sys_fsync:
	mov $0x200005F, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_fdatasync
sys_fdatasync:
	mov $0x200005F, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_ftruncate
sys_ftruncate:
	mov $0x20000C9, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_getdents64
sys_getdents64:
	mov $-78, %rax
	retq

.global sys_kill
sys_kill:
	mov $0x2000025, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

sys_errno_neg:
	mov %rax, %rdi
	xor %rax, %rax
	sub %rdi, %rax
	retq
