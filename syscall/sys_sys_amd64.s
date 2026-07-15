.text
# library/sys package externs → linker symbols sys_<name>.
# x86_64 Linux: arg4+ uses r10 (ABI passes 4th in rcx).

.global sys_socket
sys_socket:
	mov $41, %rax
	syscall
	retq

.global sys_bind
sys_bind:
	mov $49, %rax
	syscall
	retq

.global sys_connect
sys_connect:
	mov $42, %rax
	syscall
	retq

.global sys_listen
sys_listen:
	mov $50, %rax
	syscall
	retq

.global sys_accept4
sys_accept4:
	mov %rcx, %r10
	mov $288, %rax
	syscall
	retq

# eventfd(initval, flags) maps to eventfd2.
.global sys_eventfd
sys_eventfd:
	mov $290, %rax
	syscall
	retq

# No dedicated send/recv on x86_64; use sendto/recvfrom with NULL peer.
.global sys_send
sys_send:
	mov %rcx, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $44, %rax
	syscall
	retq

.global sys_sendto
sys_sendto:
	mov %rcx, %r10
	mov $44, %rax
	syscall
	retq

.global sys_recv
sys_recv:
	mov %rcx, %r10
	xor %r8, %r8
	xor %r9, %r9
	mov $45, %rax
	syscall
	retq

.global sys_recvfrom
sys_recvfrom:
	mov %rcx, %r10
	mov $45, %rax
	syscall
	retq

.global sys_shutdown
sys_shutdown:
	mov $48, %rax
	syscall
	retq

.global sys_setsockopt
sys_setsockopt:
	mov %rcx, %r10
	mov $54, %rax
	syscall
	retq

.global sys_getsockopt
sys_getsockopt:
	mov %rcx, %r10
	mov $55, %rax
	syscall
	retq

# libc getaddrinfo — no raw syscall. Stub returns EAI_FAIL (-4).
.global sys_getaddrinfo
sys_getaddrinfo:
	mov $-4, %rax
	retq

.global sys_fcntl
sys_fcntl:
	mov $72, %rax
	syscall
	retq

.global sys_read
sys_read:
	xor %rax, %rax
	syscall
	retq

.global sys_write
sys_write:
	mov $1, %rax
	syscall
	retq

.global sys_close
sys_close:
	mov $3, %rax
	syscall
	retq

.global sys_socketpair
sys_socketpair:
	mov %rcx, %r10
	mov $53, %rax
	syscall
	retq

.global sys_epoll_create1
sys_epoll_create1:
	mov $291, %rax
	syscall
	retq

.global sys_epoll_ctl
sys_epoll_ctl:
	mov %rcx, %r10
	mov $233, %rax
	syscall
	retq

.global sys_epoll_wait
sys_epoll_wait:
	mov %rcx, %r10
	mov $232, %rax
	syscall
	retq

.global sys_readlink
sys_readlink:
	mov $89, %rax
	syscall
	retq

.global sys_rename
sys_rename:
	mov $82, %rax
	syscall
	retq

.global sys_link
sys_link:
	mov $86, %rax
	syscall
	retq

.global sys_symlink
sys_symlink:
	mov $88, %rax
	syscall
	retq
