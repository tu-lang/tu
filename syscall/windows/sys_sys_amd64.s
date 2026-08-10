# library/sys → sys_* . Net returns -ENOSYS; fs aliases std_*.
.text
.global sys_socket
sys_socket:
	mov $-38, %rax
	retq
.global sys_bind
sys_bind:
	mov $-38, %rax
	retq
.global sys_connect
sys_connect:
	mov $-38, %rax
	retq
.global sys_listen
sys_listen:
	mov $-38, %rax
	retq
.global sys_accept4
sys_accept4:
	mov $-38, %rax
	retq
.global sys_eventfd
sys_eventfd:
	mov $-38, %rax
	retq
.global sys_send
sys_send:
	mov $-38, %rax
	retq
.global sys_sendto
sys_sendto:
	mov $-38, %rax
	retq
.global sys_recv
sys_recv:
	mov $-38, %rax
	retq
.global sys_recvfrom
sys_recvfrom:
	mov $-38, %rax
	retq
.global sys_shutdown
sys_shutdown:
	mov $-38, %rax
	retq
.global sys_setsockopt
sys_setsockopt:
	mov $-38, %rax
	retq
.global sys_getsockopt
sys_getsockopt:
	mov $-38, %rax
	retq
.global sys_getaddrinfo
sys_getaddrinfo:
	mov $-38, %rax
	retq
.global sys_fcntl
sys_fcntl:
	mov $-38, %rax
	retq
.global sys_kqueue
sys_kqueue:
	mov $-38, %rax
	retq
.global sys_kevent
sys_kevent:
	mov $-38, %rax
	retq
.global sys_epoll_create1
sys_epoll_create1:
	mov $-38, %rax
	retq
.global sys_epoll_ctl
sys_epoll_ctl:
	mov $-38, %rax
	retq
.global sys_epoll_wait
sys_epoll_wait:
	mov $-38, %rax
	retq
.global sys_socketpair
sys_socketpair:
	mov $-38, %rax
	retq
.global sys_read
sys_read:
	jmp std_read
.global sys_write
sys_write:
	jmp std_write
.global sys_close
sys_close:
	jmp std_close
.global sys_readlink
sys_readlink:
	jmp std_readlink
.global sys_rename
sys_rename:
	mov $-38, %rax
	retq
.global sys_link
sys_link:
	mov $-38, %rax
	retq
.global sys_symlink
sys_symlink:
	mov $-38, %rax
	retq
.global sys_openat
sys_openat:
	mov $-38, %rax
	retq
.global sys_mkdir
sys_mkdir:
	mov $-38, %rax
	retq
.global sys_rmdir
sys_rmdir:
	mov $-38, %rax
	retq
.global sys_unlink
sys_unlink:
	mov $-38, %rax
	retq
.global sys_chmod
sys_chmod:
	mov $-38, %rax
	retq
.global sys_stat
sys_stat:
	jmp std_stat
.global sys_fstat
sys_fstat:
	jmp std_fstat
.global sys_lstat
sys_lstat:
	jmp std_lstat
.global sys_lseek
sys_lseek:
	jmp std_seek
.global sys_fsync
sys_fsync:
	xor %eax, %eax
	retq
.global sys_fdatasync
sys_fdatasync:
	xor %eax, %eax
	retq
.global sys_ftruncate
sys_ftruncate:
	mov $-38, %rax
	retq
.global sys_getdents64
sys_getdents64:
	jmp std_getdents
.global sys_kill
sys_kill:
	mov $-38, %rax
	retq
