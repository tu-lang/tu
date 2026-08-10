# Darwin stubs for library/sys — keep symbol surface; ENOSYS (-78) where absent.
# Enough for link; networking/epoll not in Phase 3a smoke.
.text
.global sys_socket
sys_socket:
	# Linux or's SOCK_NONBLOCK(0x800)|SOCK_CLOEXEC(0x80000) into type; Darwin
	# rejects those bits — strip, socket(), then fcntl NONBLOCK/CLOEXEC.
	# AF_INET6: Linux=10 → Darwin=30.
	# Force 16-byte align before libSystem (Tu frames may be misaligned).
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %rax
	and $-16, %rsp
	mov %rsi, %rbx
	xor %r12, %r12
	xor %r13, %r13
	mov %ebx, %eax
	and $0x800, %eax
	cmp $0, %eax
	je sys_socket_no_nb
	mov $1, %r12
sys_socket_no_nb:
	mov %ebx, %eax
	and $0x80000, %eax
	cmp $0, %eax
	je sys_socket_no_ce
	mov $1, %r13
sys_socket_no_ce:
	mov %ebx, %eax
	and $0x800, %eax
	sub %eax, %ebx
	mov %ebx, %eax
	mov $0x80000, %ecx
	and %ecx, %eax
	sub %eax, %ebx
	cmp $10, %edi
	jne sys_socket_af_ok
	mov $30, %edi
sys_socket_af_ok:
	mov %ebx, %esi
	call _socket
	cmp $-1, %rax
	jne sys_socket_fcntl
	mov $-22, %rax
	jmp sys_socket_done
sys_socket_fcntl:
	mov %rax, %rbx
	cmp $0, %r12
	je sys_socket_ce
	mov %ebx, %edi
	mov $4, %esi
	mov $4, %edx
	call _fcntl
sys_socket_ce:
	cmp $0, %r13
	je sys_socket_ret_fd
	mov %ebx, %edi
	mov $2, %esi
	mov $1, %edx
	call _fcntl
sys_socket_ret_fd:
	mov %rbx, %rax
sys_socket_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_bind
sys_bind:
	# Convert Linux sockaddr_* (family u16 at 0) → Darwin (len u8 + family u8).
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %rax
	and $-16, %rsp
	sub $128, %rsp
	mov %rdi, %rbx
	movzwl (%rsi), %eax
	cmp $2, %eax
	je sys_bind_v4
	cmp $10, %eax
	je sys_bind_v6
	jmp sys_bind_call
sys_bind_v4:
	movb $16, (%rsp)
	movb $2, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	mov %rsp, %rsi
	mov $16, %edx
	jmp sys_bind_call
sys_bind_v6:
	movb $28, (%rsp)
	movb $30, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	movq 16(%rsi), %rax
	movq %rax, 16(%rsp)
	movl 24(%rsi), %eax
	movl %eax, 24(%rsp)
	mov %rsp, %rsi
	mov $28, %edx
sys_bind_call:
	mov %rbx, %rdi
	call _bind
	cmp $-1, %rax
	jne sys_bind_ok
	mov $-22, %rax
sys_bind_ok:
	mov -8(%rbp), %rbx
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_connect
sys_connect:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %rax
	and $-16, %rsp
	sub $128, %rsp
	mov %rdi, %rbx
	movzwl (%rsi), %eax
	cmp $2, %eax
	je sys_connect_v4
	cmp $10, %eax
	je sys_connect_v6
	jmp sys_connect_call
sys_connect_v4:
	movb $16, (%rsp)
	movb $2, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	mov %rsp, %rsi
	mov $16, %edx
	jmp sys_connect_call
sys_connect_v6:
	movb $28, (%rsp)
	movb $30, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	movq 16(%rsi), %rax
	movq %rax, 16(%rsp)
	movl 24(%rsi), %eax
	movl %eax, 24(%rsp)
	mov %rsp, %rsi
	mov $28, %edx
sys_connect_call:
	mov %rbx, %rdi
	call _connect
	cmp $-1, %rax
	jne sys_connect_ok
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
sys_connect_ok:
	mov -8(%rbp), %rbx
	mov %rbp, %rsp
	pop %rbp
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
	# Darwin has accept(3), not accept4. Ignore Linux flags; fcntl NONBLOCK+CLOEXEC.
	# Convert returned sockaddr Darwin→Linux layout for Tu SockaddrIn readers.
	# Return -errno immediately on failure (including EAGAIN). Do not sleep-retry:
	# async accept must surface WouldBlock so poll_read_ready can wait; a prior
	# 50×1ms EAGAIN loop also clobbered %edi before building -errno.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %rbx, %rdi
	mov %r12, %rsi
	mov %r13, %rdx
	call _accept
	cmp $-1, %rax
	jne sys_accept4_ok_fd
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
	jmp sys_accept4_done
sys_accept4_ok_fd:
	mov %rax, %rbx
	cmp $0, %r12
	je sys_accept4_flags
	mov %r12, %rsi
	movb 1(%rsi), %al
	cmp $2, %al
	je sys_accept4_v4
	cmp $30, %al
	jne sys_accept4_flags
	movw $10, (%rsi)
	jmp sys_accept4_flags
sys_accept4_v4:
	movw $2, (%rsi)
sys_accept4_flags:
	mov %r14, %rax
	and $0x800, %eax
	cmp $0, %eax
	je sys_accept4_ce
	mov %ebx, %edi
	mov $4, %esi
	mov $4, %edx
	call _fcntl
sys_accept4_ce:
	mov %r14, %rax
	and $0x80000, %eax
	cmp $0, %eax
	je sys_accept4_ret
	mov %ebx, %edi
	mov $2, %esi
	mov $1, %edx
	call _fcntl
sys_accept4_ret:
	mov %rbx, %rax
sys_accept4_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov %rbp, %rsp
	pop %rbp
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
	# sendto(fd, buf, len, flags, addr, addrlen) — Linux sockaddr → Darwin.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	sub $128, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %r8, %rsi
	cmp $0, %rsi
	je sys_sendto_noaddr
	movzwl (%rsi), %eax
	cmp $2, %eax
	je sys_sendto_v4
	cmp $10, %eax
	je sys_sendto_v6
	mov %r8, %rsi
	jmp sys_sendto_call
sys_sendto_v4:
	movb $16, (%rsp)
	movb $2, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	mov %rsp, %r8
	mov $16, %r9
	jmp sys_sendto_call
sys_sendto_v6:
	movb $28, (%rsp)
	movb $30, 1(%rsp)
	movw 2(%rsi), %ax
	movw %ax, 2(%rsp)
	movl 4(%rsi), %eax
	movl %eax, 4(%rsp)
	movq 8(%rsi), %rax
	movq %rax, 8(%rsp)
	movq 16(%rsi), %rax
	movq %rax, 16(%rsp)
	movl 24(%rsi), %eax
	movl %eax, 24(%rsp)
	mov %rsp, %r8
	mov $28, %r9
	jmp sys_sendto_call
sys_sendto_noaddr:
	xor %r8, %r8
	xor %r9, %r9
sys_sendto_call:
	mov %rbx, %rdi
	mov %r12, %rsi
	mov %r13, %rdx
	mov %r14, %rcx
	call _sendto
	cmp $-1, %rax
	jne sys_sendto_ok
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
sys_sendto_ok:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov %rbp, %rsp
	pop %rbp
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
	# recvfrom + Darwin sockaddr → Linux family layout for Tu readers.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	# r8=addr, r9=addrlen stay for call
	mov %rbx, %rdi
	mov %r12, %rsi
	mov %r13, %rdx
	mov %r14, %rcx
	call _recvfrom
	cmp $-1, %rax
	jne sys_recvfrom_ok
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
	jmp sys_recvfrom_done
sys_recvfrom_ok:
	cmp $0, %r8
	je sys_recvfrom_done
	mov %r8, %rsi
	movb 1(%rsi), %cl
	cmp $2, %cl
	je sys_recvfrom_v4
	cmp $30, %cl
	jne sys_recvfrom_done
	movw $10, (%rsi)
	jmp sys_recvfrom_done
sys_recvfrom_v4:
	movw $2, (%rsi)
sys_recvfrom_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov -32(%rbp), %r14
	mov %rbp, %rsp
	pop %rbp
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
	# Linux SOL_SOCKET=1 → Darwin 0xffff; SO_REUSEADDR=2 → 0x0004; SO_KEEPALIVE=9 → 0x0008.
	cmp $1, %esi
	jne sys_setsockopt_level_ok
	mov $0xffff, %esi
sys_setsockopt_level_ok:
	cmp $0xffff, %esi
	jne sys_setsockopt_do
	cmp $2, %edx
	jne sys_setsockopt_ka
	mov $4, %edx
	jmp sys_setsockopt_do
sys_setsockopt_ka:
	cmp $9, %edx
	jne sys_setsockopt_do
	mov $8, %edx
sys_setsockopt_do:
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
	# Linux F_DUPFD_CLOEXEC=1030 → Darwin 67.
	cmp $1030, %esi
	jne sys_fcntl_nonblock
	mov $67, %esi
	jmp sys_fcntl_call
sys_fcntl_nonblock:
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
	and $-16, %rsp
	call _fcntl
	mov %rbp, %rsp
	pop %rbp
	cmp $-1, %rax
	jne sys_fcntl_ok
	mov $-22, %rax
sys_fcntl_ok:
	retq

# kqueue(2) / kevent(2) — Darwin poll backend (mio-compatible Selector).
.global sys_kqueue
sys_kqueue:
	mov $0x200016A, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_kevent
sys_kevent:
	# C ABI 4th arg in %rcx; Darwin syscall wants %r10.
	mov %rcx, %r10
	mov $0x200016B, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_errno_neg
	retq

.global sys_read
sys_read:
	# If fd is the Darwin signalfd kqueue, harvest EVFILT_SIGNAL into buf.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	mov %rdi, %rbx
	mov %rsi, %r12
	mov %rdx, %r13
	mov darwin_sfd_kq(%rip), %rax
	cmp $0, %rax
	je sys_read_normal
	cmp %rax, %rbx
	jne sys_read_normal
	# kevent(kq, NULL, 0, eventlist=stack, 1, timeout=0)
	sub $48, %rsp
	# zero timespec at 32(%rsp)
	movq $0, 32(%rsp)
	movq $0, 40(%rsp)
	mov %rbx, %rdi
	xor %rsi, %rsi
	xor %rdx, %rdx
	mov %rsp, %rcx
	mov $1, %r8
	lea 32(%rsp), %r9
	mov %rcx, %r10
	mov $0x200016B, %rax
	syscall
	setb %cl
	cmp $0, %cl
	jne sys_read_sfd_err
	cmp $0, %rax
	je sys_read_sfd_eagain
	# event.ident (signum) → ssi_signo at buf[0]
	# Do not store through %r12 directly — asmer mis-encodes (%r12).
	mov 0(%rsp), %eax
	mov %r12, %rsi
	movl %eax, 0(%rsi)
	xor %eax, %eax
	movl %eax, 4(%rsi)
	movq %rax, 8(%rsi)
	mov $128, %rax
	add $48, %rsp
	jmp sys_read_done
sys_read_sfd_eagain:
	# Linux EAGAIN
	mov $-11, %rax
	add $48, %rsp
	jmp sys_read_done
sys_read_sfd_err:
	add $48, %rsp
	mov %rax, %rdi
	call darwin_errno_neg
	jmp sys_read_done
sys_read_normal:
	mov %rbx, %rdi
	mov %r12, %rsi
	mov %r13, %rdx
	call _read
	cmp $-1, %rax
	jne sys_read_done
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
sys_read_done:
	mov -8(%rbp), %rbx
	mov -16(%rbp), %r12
	mov -24(%rbp), %r13
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_write
sys_write:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _write
	cmp $-1, %rax
	jne sys_write_ok
	call ___error
	mov (%rax), %edi
	call darwin_errno_neg
sys_write_ok:
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_close
sys_close:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	# Closing the Darwin signalfd kqueue must clear the global so a recycled
	# fd is not hijacked by sys_read's EVFILT_SIGNAL harvest.
	mov darwin_sfd_kq(%rip), %rax
	cmp $0, %rax
	je sys_close_do
	cmp %rax, %rdi
	jne sys_close_do
	movq $0, darwin_sfd_kq(%rip)
	movq $0, darwin_sfd_mask(%rip)
sys_close_do:
	call _close
	cmp $-1, %rax
	jne sys_close_ok
	call ___error
	mov 0(%rax), %edi
	call darwin_errno_neg
sys_close_ok:
	mov %rbp, %rsp
	pop %rbp
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

# epoll is Linux-only; Darwin netio installs kqueue.tu over epoll.tu.
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
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _openat
	cmp $-1, %rax
	jne sys_openat_ok
	call ___error
	mov 0(%rax), %edi
	call darwin_errno_neg
sys_openat_ok:
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_mkdir
sys_mkdir:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _mkdir
	cmp $-1, %rax
	jne sys_mkdir_ok
	call ___error
	mov 0(%rax), %edi
	call darwin_errno_neg
sys_mkdir_ok:
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_rmdir
sys_rmdir:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _rmdir
	cmp $-1, %rax
	jne sys_rmdir_ok
	call ___error
	mov 0(%rax), %edi
	call darwin_errno_neg
sys_rmdir_ok:
	mov %rbp, %rsp
	pop %rbp
	retq

.global sys_unlink
sys_unlink:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	call _unlink
	cmp $-1, %rax
	jne sys_unlink_ok
	call ___error
	mov 0(%rax), %edi
	call darwin_errno_neg
sys_unlink_ok:
	mov %rbp, %rsp
	pop %rbp
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
	# Remap Darwin stat64 into Linux-shaped Tu Stat (see std_stat).
	jmp std_stat

.global sys_fstat
sys_fstat:
	jmp std_fstat

.global sys_lstat
sys_lstat:
	jmp std_lstat

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
	# Convert getdirentries64 → linux_dirent64 layout (std_getdents).
	jmp std_getdents

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
	jmp darwin_errno_neg

# Darwin errno (positive in %edi) → Linux-style -errno in %rax.
# Tu library/sys decode_error_code is Linux-numbered; raw Darwin EAGAIN=35
# collides with Linux EDEADLK=-35 and must not be passed through.
darwin_errno_neg:
	cmp $11, %edi
	jne den_chk_35
	# Darwin EDEADLK=11 → Linux 35
	mov $-35, %rax
	retq
den_chk_35:
	cmp $35, %edi
	jne den_chk_36
	# Darwin EAGAIN/EWOULDBLOCK=35 → Linux 11
	mov $-11, %rax
	retq
den_chk_36:
	cmp $36, %edi
	jne den_chk_37
	mov $-115, %rax
	retq
den_chk_37:
	cmp $37, %edi
	jne den_chk_38
	mov $-114, %rax
	retq
den_chk_38:
	cmp $38, %edi
	jne den_chk_39
	mov $-88, %rax
	retq
den_chk_39:
	cmp $39, %edi
	jne den_chk_40
	mov $-89, %rax
	retq
den_chk_40:
	cmp $40, %edi
	jne den_chk_41
	mov $-90, %rax
	retq
den_chk_41:
	cmp $41, %edi
	jne den_chk_42
	mov $-91, %rax
	retq
den_chk_42:
	cmp $42, %edi
	jne den_chk_43
	mov $-92, %rax
	retq
den_chk_43:
	cmp $43, %edi
	jne den_chk_44
	mov $-93, %rax
	retq
den_chk_44:
	cmp $44, %edi
	jne den_chk_45
	mov $-94, %rax
	retq
den_chk_45:
	cmp $45, %edi
	jne den_chk_46
	mov $-95, %rax
	retq
den_chk_46:
	cmp $46, %edi
	jne den_chk_47
	mov $-96, %rax
	retq
den_chk_47:
	cmp $47, %edi
	jne den_chk_48
	mov $-97, %rax
	retq
den_chk_48:
	cmp $48, %edi
	jne den_chk_49
	mov $-98, %rax
	retq
den_chk_49:
	cmp $49, %edi
	jne den_chk_50
	mov $-99, %rax
	retq
den_chk_50:
	cmp $50, %edi
	jne den_chk_51
	mov $-100, %rax
	retq
den_chk_51:
	cmp $51, %edi
	jne den_chk_52
	mov $-101, %rax
	retq
den_chk_52:
	cmp $52, %edi
	jne den_chk_53
	mov $-102, %rax
	retq
den_chk_53:
	cmp $53, %edi
	jne den_chk_54
	mov $-103, %rax
	retq
den_chk_54:
	cmp $54, %edi
	jne den_chk_55
	mov $-104, %rax
	retq
den_chk_55:
	cmp $55, %edi
	jne den_chk_56
	mov $-105, %rax
	retq
den_chk_56:
	cmp $56, %edi
	jne den_chk_57
	mov $-106, %rax
	retq
den_chk_57:
	cmp $57, %edi
	jne den_chk_58
	mov $-107, %rax
	retq
den_chk_58:
	cmp $58, %edi
	jne den_chk_59
	mov $-108, %rax
	retq
den_chk_59:
	cmp $59, %edi
	jne den_chk_60
	mov $-109, %rax
	retq
den_chk_60:
	cmp $60, %edi
	jne den_chk_61
	mov $-110, %rax
	retq
den_chk_61:
	cmp $61, %edi
	jne den_chk_62
	mov $-111, %rax
	retq
den_chk_62:
	cmp $62, %edi
	jne den_chk_63
	mov $-40, %rax
	retq
den_chk_63:
	cmp $63, %edi
	jne den_chk_64
	mov $-36, %rax
	retq
den_chk_64:
	cmp $64, %edi
	jne den_chk_65
	mov $-112, %rax
	retq
den_chk_65:
	cmp $65, %edi
	jne den_identity
	mov $-113, %rax
	retq
den_identity:
	xor %rax, %rax
	sub %rdi, %rax
	retq

