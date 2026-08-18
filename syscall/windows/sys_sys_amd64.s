# library/sys sys_* : Winsock BSD surface + WSAPoll-backed software epoll.
# Linux SOL_SOCKET / SO_* / AF_INET6 / errno numbers translated at the boundary.
.text

# ---- WSAStartup + Linux-style -errno from WSAGetLastError ----
# Always call WSAStartup (safe to repeat). A separate ready .long symbol
# AV'd under peff/asmer rip-relative loads.
win_wsa_ensure:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov $0x0202, %rcx
	lea win_wsadata(%rip), %rdx
	call WSAStartup
	cmp $0, %eax
	jne wwe_fail
	mov %rbp, %rsp
	pop %rbp
	xor %eax, %eax
	ret
wwe_fail:
	mov %rbp, %rsp
	pop %rbp
	mov $-38, %rax
	ret

# edi = positive WSA error; rax = Linux -errno
# Thin trampoline: Tu stack ABI �?push arg, call; callee cleans args.
.globl win_wsa_errno_neg
win_wsa_errno_neg:
	movsxd %edi, %rax
	push %rax
	call runtime_win_wsa_errno_neg
	ret

win_wsa_fail:
	call WSAGetLastError
	mov %eax, %edi
	call win_wsa_errno_neg
	ret

# SysV no-body fns called from runtime/epoll_soft.tu (registercall).
.global runtime_win_api_wsapoll
runtime_win_api_wsapoll:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdx, %r8
	mov %rsi, %rdx
	mov %rdi, %rcx
	call WSAPoll
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_accept
runtime_win_api_accept:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	xor %edx, %edx
	xor %r8, %r8
	call accept
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_recv
runtime_win_api_recv:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rcx, %r9
	mov %rdx, %r8
	mov %rsi, %rdx
	mov %rdi, %rcx
	call recv
	movsxd %eax, %rax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_sleep
runtime_win_api_sleep:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %edi, %ecx
	call Sleep
	xor %eax, %eax
	mov %rbp, %rsp
	pop %rbp
	retq

.global runtime_win_api_wsafail
runtime_win_api_wsafail:
	jmp win_wsa_fail

# SysV trampolines → Tu stack ABI. Framed sys_* must call these, not Tu directly.
.global win_sockaddr_win_copy
win_sockaddr_win_copy:
	push %rdx
	push %rsi
	push %rdi
	call runtime_win_sockaddr_win_copy_tu
	ret

.global win_sockaddr_to_linux
win_sockaddr_to_linux:
	push %rdi
	call runtime_win_sockaddr_to_linux_tu
	ret

.global win_eventfd_loopback
win_eventfd_loopback:
	push %rdi
	call runtime_win_eventfd_loopback_tu
	ret

# ---- socket ----
.global sys_socket
sys_socket:
	# SysV: rdi=domain rsi=type rdx=protocol
	# Strip Linux SOCK_NONBLOCK(0x800)|SOCK_CLOEXEC(0x80000); AF_INET6 10?23.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	xor %r14, %r14
	mov %r13, %rax
	and $0x800, %rax
	cmp $0, %rax
	je ss_no_nb
	mov $1, %r14
ss_no_nb:
	mov %r13, %rax
	and $0x800, %rax
	sub %rax, %r13
	mov %r13, %rax
	and $0x80000, %rax
	sub %rax, %r13
	cmp $10, %r12
	jne ss_af
	mov $23, %r12
ss_af:
	call win_wsa_ensure
	cmp $0, %rax
	jne ss_err
	mov %r12, %rcx
	mov %r13, %rdx
	mov %rbx, %r8
	call socket
	cmp $-1, %rax
	je ss_wsa
	mov %rax, %rbx
	mov %rax, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je ss_alloc_fail
	mov %eax, %eax
	mov %rax, %r12
	mov %r12, %rdi
	call win_fd_mark_sock
	cmp $0, %r14
	je ss_ret
	mov %r12, %rdi
	call win_fd_get
	mov %rax, %rcx
	mov $1, %eax
	mov %eax, 32(%rsp)
	mov $0x8004667E, %rdx
	lea 32(%rsp), %r8
	call ioctlsocket
ss_ret:
	mov %r12, %rax
	jmp ss_out
ss_alloc_fail:
	mov %rbx, %rcx
	call closesocket
ss_wsa:
	call win_wsa_fail
	jmp ss_out
ss_err:
	mov $-38, %rax
ss_out:
	lea -32(%rbp), %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

# ---- bind ----
.global sys_bind
sys_bind:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $192, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	call win_fd_get
	cmp $0, %rax
	je sb_err
	mov %rax, %rbx
	mov %r12, %rdi
	mov %r13, %rsi
	lea 32(%rsp), %rdx
	call win_sockaddr_win_copy
	mov %rax, %r12
	mov %rbx, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	call bind
	cmp $0, %eax
	je sb_ok
	call win_wsa_fail
	jmp sb_out
sb_ok:
	xor %eax, %eax
	jmp sb_out
sb_err:
	mov $-9, %rax
sb_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq
.global sys_connect
sys_connect:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $192, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	call win_fd_get
	cmp $0, %rax
	je scn_err
	mov %rax, %rbx
	mov %r12, %rdi
	mov %r13, %rsi
	lea 32(%rsp), %rdx
	call win_sockaddr_win_copy
	mov %rax, %r12
	mov %rbx, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	call connect
	cmp $0, %eax
	je scn_ok
	call WSAGetLastError
	cmp $10035, %eax
	je scn_inprog
	cmp $10036, %eax
	je scn_inprog
	mov %eax, %edi
	call win_wsa_errno_neg
	jmp scn_out
scn_inprog:
	mov $-115, %rax
	jmp scn_out
scn_ok:
	xor %eax, %eax
	jmp scn_out
scn_err:
	mov $-9, %rax
scn_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq
.global sys_listen
sys_listen:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %r12
	mov %rsi, %rbx
	call win_fd_get
	cmp $0, %rax
	je sln_err
	mov %rax, %rcx
	mov %rbx, %rdx
	call listen
	cmp $0, %eax
	je sln_ok
	call win_wsa_fail
	jmp sln_out
sln_ok:
	# WSAPoll never signals listen POLLIN; mark fd for accept-probe in epoll_wait.
	cmp $0, %r12
	jl sln_ok0
	cmp $256, %r12
	jge sln_ok0
	lea win_fd_listen(%rip), %rax
	add %r12, %rax
	movb $1, (%rax)
sln_ok0:
	xor %eax, %eax
	jmp sln_out
sln_err:
	mov $-9, %rax
sln_out:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

# ---- accept4 ----
.global sys_accept4
sys_accept4:
	# rdi=fd rsi=addr rdx=addrlen* rcx=flags (SOCK_NONBLOCK/CLOEXEC)
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $48, %rsp
	mov %rdi, %r15
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	# Deliver socket stashed by epoll_wait listen probe, if any.
	cmp $0, %r15
	jl sa4_nostash
	cmp $256, %r15
	jge sa4_nostash
	lea win_accept_stash(%rip), %rax
	mov %r15, %rcx
	shl $3, %rcx
	add %rcx, %rax
	mov (%rax), %rbx
	cmp $0, %rbx
	je sa4_nostash
	movq $0, (%rax)
	# Probe accept used NULL addr; fill peer for callers that need it.
	cmp $0, %r12
	je sa4_nb
	cmp $0, %r13
	je sa4_nb
	mov %rbx, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	call getpeername
	jmp sa4_nb
sa4_nostash:
	mov %r15, %rdi
	call win_fd_get
	cmp $0, %rax
	je sa4_err
	mov %rax, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	call accept
	cmp $-1, %rax
	je sa4_wsa
	mov %rax, %rbx
	# Skip AF_INET6 family rewrite on the listen socket itself.
	# Peer sockaddr is rewritten via win_sockaddr_to_linux_tu after accept/getpeername.
sa4_nb:
	mov %r12, %rdi
	call win_sockaddr_to_linux
	mov %r14, %rax
	and $0x800, %rax
	cmp $0, %rax
	je sa4_alloc
	mov %rbx, %rcx
	mov $1, %edx
	mov %edx, 32(%rsp)
	mov $0x8004667E, %rdx
	lea 32(%rsp), %r8
	call ioctlsocket
sa4_alloc:
	mov %rbx, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je sa4_afail
	mov %eax, %eax
	mov %rax, %r12
	mov %r12, %rdi
	call win_fd_mark_sock
	mov %r12, %rax
	jmp sa4_out
sa4_afail:
	mov %rbx, %rcx
	call closesocket
	mov $-24, %rax
	jmp sa4_out
sa4_wsa:
	call win_wsa_fail
	jmp sa4_out
sa4_err:
	mov $-9, %rax
sa4_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

# Free software-epoll set slot (used[] + n[]). rdi=ep_idx 0..15.
.globl win_ep_release_idx
win_ep_release_idx:
	cmp $0, %rdi
	jl weri_out
	cmp $16, %rdi
	jge weri_out
	lea win_ep_used(%rip), %rax
	add %rdi, %rax
	movb $0, (%rax)
	lea win_ep_n(%rip), %rax
	mov %rdi, %rcx
	shl $2, %rcx
	add %rcx, %rax
	movl $0, (%rax)
weri_out:
	ret

# ---- send / sendto / recv / recvfrom ----
.global sys_send
sys_send:
	# rdi=fd rsi=buf rdx=len rcx=flags ? ignore MSG_NOSIGNAL
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $32, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %rbx
	# Drop Linux MSG_NOSIGNAL (0x4000); Winsock has no equivalent.
	mov %rbx, %rax
	and $0x4000, %rax
	sub %rax, %rbx
	call win_fd_get
	cmp $0, %rax
	je ssend_err
	mov %rax, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %rbx, %r9
	call send
	cmp $-1, %eax
	jne ssend_out
	call win_wsa_fail
	jmp ssend_out
ssend_err:
	mov $-9, %rax
ssend_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_sendto
sys_sendto:
	# rdi=fd rsi=buf rdx=len rcx=flags r8=addr r9=addrlen
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $192, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %r14, %rax
	and $0x4000, %rax
	sub %rax, %r14
	mov %r8, %r15
	mov %r9, %rbx
	call win_fd_get
	cmp $0, %rax
	je ssto_err
	mov %rax, 48(%rsp)
	mov %r12, 8(%rsp)
	mov %r13, 16(%rsp)
	mov %r14, 24(%rsp)
	mov %rbx, 56(%rsp)
	mov %r15, %rdi
	mov %rbx, %rsi
	lea 64(%rsp), %rdx
	call win_sockaddr_win_copy
	mov %rax, %r15
	mov 8(%rsp), %r12
	mov 16(%rsp), %r13
	mov 24(%rsp), %r14
	mov 56(%rsp), %rbx
ssto_call:
	mov 48(%rsp), %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %r14, %r9
	mov %r15, 32(%rsp)
	mov %rbx, 40(%rsp)
	call sendto
	cmp $-1, %eax
	jne ssto_out
	call win_wsa_fail
	jmp ssto_out
ssto_err:
	mov $-9, %rax
ssto_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_recv
sys_recv:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $32, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %rbx
	call win_fd_get
	cmp $0, %rax
	je srecv_err
	mov %rax, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %rbx, %r9
	call recv
	cmp $-1, %eax
	jne srecv_out
	call win_wsa_fail
	jmp srecv_out
srecv_err:
	mov $-9, %rax
srecv_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_recvfrom
sys_recvfrom:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $48, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %r8, %r15
	mov %r9, %rbx
	call win_fd_get
	cmp $0, %rax
	je srf_err
	mov %rax, %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %r14, %r9
	mov %r15, 32(%rsp)
	mov %rbx, 40(%rsp)
	call recvfrom
	cmp $-1, %eax
	jne srf_fix
	call win_wsa_fail
	jmp srf_out
srf_fix:
	mov %eax, 24(%rsp)
	mov %r15, %rdi
	call win_sockaddr_to_linux
	mov 24(%rsp), %eax
	movsxd %eax, %rax
	jmp srf_out
srf_err:
	mov $-9, %rax
srf_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_shutdown
sys_shutdown:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov %rsi, %rbx
	call win_fd_get
	cmp $0, %rax
	je ssh_err
	mov %rax, %rcx
	mov %rbx, %rdx
	call shutdown
	cmp $0, %eax
	je ssh_ok
	call win_wsa_fail
	jmp ssh_out
ssh_ok:
	xor %eax, %eax
	jmp ssh_out
ssh_err:
	mov $-9, %rax
ssh_out:
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.global sys_setsockopt
sys_setsockopt:
	# rdi=fd rsi=level rdx=optname rcx=optval r8=optlen
	# SOL_SOCKET 1?0xFFFF; SO_REUSEADDR 2?4; SO_KEEPALIVE 9?8; SO_ERROR 4?0x1007
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	sub $64, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %r8, %rbx
	call win_fd_get
	cmp $0, %rax
	je sso_err
	mov %rax, 48(%rsp)
	cmp $1, %r12
	jne sso_lvl
	mov $0xFFFF, %r12
sso_lvl:
	cmp $0xFFFF, %r12
	jne sso_opt
	cmp $2, %r13
	jne sso_ka
	mov $4, %r13
	jmp sso_opt
sso_ka:
	cmp $9, %r13
	jne sso_errn
	mov $8, %r13
	jmp sso_opt
sso_errn:
	cmp $4, %r13
	jne sso_opt
	mov $0x1007, %r13
sso_opt:
	mov 48(%rsp), %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %r14, %r9
	mov %rbx, 32(%rsp)
	call setsockopt
	cmp $0, %eax
	je sso_ok
	call win_wsa_fail
	jmp sso_out
sso_ok:
	xor %eax, %eax
	jmp sso_out
sso_err:
	mov $-9, %rax
sso_out:
	lea -32(%rbp), %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_getsockopt
sys_getsockopt:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	and $-16, %rsp
	sub $64, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	mov %r8, %rbx
	call win_fd_get
	cmp $0, %rax
	je sgs_err
	mov %rax, 48(%rsp)
	cmp $1, %r12
	jne sgs_lvl
	mov $0xFFFF, %r12
sgs_lvl:
	cmp $4, %r13
	jne sgs_opt
	cmp $0xFFFF, %r12
	jne sgs_opt
	mov $0x1007, %r13
sgs_opt:
	mov 48(%rsp), %rcx
	mov %r12, %rdx
	mov %r13, %r8
	mov %r14, %r9
	mov %rbx, 32(%rsp)
	call getsockopt
	cmp $0, %eax
	je sgs_ok
	call win_wsa_fail
	jmp sgs_out
sgs_ok:
	xor %eax, %eax
	jmp sgs_out
sgs_err:
	mov $-9, %rax
sgs_out:
	lea -32(%rbp), %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_getaddrinfo
sys_getaddrinfo:
	mov $-38, %rax
	retq

.global sys_fcntl
sys_fcntl:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $48, %rsp
	mov %rsi, %r12
	mov %rdx, %rbx
	call win_fd_get
	cmp $0, %rax
	je sfc_err
	cmp $4, %r12
	jne sfc_ok0
	mov %rax, %rcx
	xor %rdx, %rdx
	mov %rbx, %rax
	and $2048, %rax
	cmp $0, %rax
	je sfc_nb
	mov $1, %rdx
sfc_nb:
	mov %edx, 32(%rsp)
	mov $0x8004667E, %rdx
	lea 32(%rsp), %r8
	call ioctlsocket
	cmp $0, %eax
	jne sfc_wsa
sfc_ok0:
	xor %eax, %eax
	jmp sfc_out
sfc_wsa:
	call win_wsa_fail
	jmp sfc_out
sfc_err:
	mov $-1, %rax
sfc_out:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

# ---- eventfd via UDP loopback (waker) ----
.global sys_eventfd
sys_eventfd:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $96, %rsp
	call win_wsa_ensure
	cmp $0, %eax
	jne sefd_err
	mov $2, %rcx
	mov $2, %rdx
	xor %r8, %r8
	call socket
	cmp $-1, %rax
	je sefd_wsa
	mov %rax, %rbx
	lea 48(%rsp), %rdi
	call win_eventfd_loopback
	mov %rbx, %rcx
	lea 48(%rsp), %rdx
	mov $16, %r8
	call bind
	cmp $0, %eax
	jne sefd_fail_sock
	mov $16, %eax
	mov %eax, 40(%rsp)
	mov %rbx, %rcx
	lea 48(%rsp), %rdx
	lea 40(%rsp), %r8
	call getsockname
	cmp $0, %eax
	jne sefd_fail_sock
	mov %rbx, %rcx
	lea 48(%rsp), %rdx
	mov $16, %r8
	call connect
	cmp $0, %eax
	jne sefd_fail_sock
	# nonblocking
	mov $1, %edx
	mov %edx, 32(%rsp)
	mov %rbx, %rcx
	mov $0x8004667E, %rdx
	lea 32(%rsp), %r8
	call ioctlsocket
	mov %rbx, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je sefd_fail_sock
	mov %eax, %eax
	mov %rax, %r12
	mov %r12, %rdi
	call win_fd_mark_sock
	mov %r12, %rax
	jmp sefd_out
sefd_fail_sock:
	mov %rbx, %rcx
	call closesocket
sefd_wsa:
	call win_wsa_fail
	jmp sefd_out
sefd_err:
	mov $-38, %rax
sefd_out:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

# ---- software epoll over WSAPoll ----
# epfd slot holds sentinel HANDLE = (ep_idx+1). Tables: 16 sets x 128 entries.

# Free software-epoll set slot (used[] + n[]). rdi=ep_idx 0..15.
# (Definition lives earlier in this file next to accept4; keep one only.)

.global sys_epoll_create1
sys_epoll_create1:
	# Tu stack ABI (rightmost pushed first): used, n, fds, ep_map.
	# Callee cleans the four args.
	lea win_ep_fd_of(%rip), %rax
	push %rax
	lea win_fds(%rip), %rax
	push %rax
	lea win_ep_n(%rip), %rax
	push %rax
	lea win_ep_used(%rip), %rax
	push %rax
	call runtime_win_epoll_create1_tu
	retq

.global sys_epoll_ctl
sys_epoll_ctl:
	# SysV rdi=epfd rsi=op rdx=fd rcx=event*
	# Tu stack ABI: rightmost pushed first; callee cleans.
	lea win_ep_fd_of(%rip), %rax
	push %rax
	lea win_ep_toks(%rip), %rax
	push %rax
	lea win_ep_evs(%rip), %rax
	push %rax
	lea win_ep_fds(%rip), %rax
	push %rax
	lea win_ep_n(%rip), %rax
	push %rax
	lea win_ep_used(%rip), %rax
	push %rax
	push %rcx
	push %rdx
	push %rsi
	push %rdi
	call runtime_win_epoll_ctl_tu
	retq

.global sys_epoll_wait
sys_epoll_wait:
	# SysV rdi=epfd rsi=events rdx=maxevents rcx=timeout
	lea win_accept_stash(%rip), %rax
	push %rax
	lea win_fd_listen(%rip), %rax
	push %rax
	lea win_fds(%rip), %rax
	push %rax
	lea win_ep_fd_of(%rip), %rax
	push %rax
	lea win_ep_toks(%rip), %rax
	push %rax
	lea win_ep_evs(%rip), %rax
	push %rax
	lea win_ep_fds(%rip), %rax
	push %rax
	lea win_ep_n(%rip), %rax
	push %rax
	lea win_ep_used(%rip), %rax
	push %rax
	push %rcx
	push %rdx
	push %rsi
	push %rdi
	call runtime_win_epoll_wait_tu
	retq
.global sys_kqueue
sys_kqueue:
	mov $-38, %rax
	retq
.global sys_kevent
sys_kevent:
	mov $-38, %rax
	retq
.global sys_socketpair
sys_socketpair:
	mov $-38, %rax
	retq

# Sock-aware read/write: SOCKET ? recv/send, else file ReadFile/WriteFile.
.global sys_read
sys_read:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	call win_fd_is_sock
	cmp $0, %eax
	je sr_file
	mov %r12, %rdi
	call win_fd_get
	cmp $0, %rax
	je sr_bad
	mov %rax, %rcx
	mov %r13, %rdx
	mov %rbx, %r8
	xor %r9, %r9
	call recv
	cmp $-1, %eax
	jne sr_out
	call win_wsa_fail
	jmp sr_out
sr_file:
	mov %r12, %rdi
	mov %r13, %rsi
	mov %rbx, %rdx
	call std_read
	jmp sr_out
sr_bad:
	mov $-9, %rax
sr_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_write
sys_write:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %r12
	mov %rsi, %r13
	mov %rdx, %rbx
	call win_fd_is_sock
	cmp $0, %eax
	je sw_file
	mov %r12, %rdi
	call win_fd_get
	cmp $0, %rax
	je sw_bad
	mov %rax, %rcx
	mov %r13, %rdx
	mov %rbx, %r8
	xor %r9, %r9
	call send
	cmp $-1, %eax
	jne sw_out
	call win_wsa_fail
	jmp sw_out
sw_file:
	mov %r12, %rdi
	mov %r13, %rsi
	mov %rbx, %rdx
	call std_write
	jmp sw_out
sw_bad:
	mov $-9, %rax
sw_out:
	lea -24(%rbp), %rsp
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_close
sys_close:
	# Software epoll: placeholder HANDLE must not CloseHandle.
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rbx
	call win_ep_get_fd
	cmp $0xFF, %eax
	je scl_std
	lea win_ep_used(%rip), %rdx
	add %rax, %rdx
	movb $0, (%rdx)
	mov %rbx, %rdi
	call win_ep_clear_fd
	mov %rbx, %rdi
	call win_fd_slot_clear
	xor %eax, %eax
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq
scl_std:
	mov %rbx, %rdi
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
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
	cmp $-100, %edi
	jne soat_enosys
	mov %rsi, %rdi
	mov %rdx, %rsi
	jmp std_open
soat_enosys:
	mov $-38, %rax
	retq
.global sys_mkdir
sys_mkdir:
	jmp std_mkdir
.global sys_rmdir
sys_rmdir:
	jmp std_rmdir
.global sys_unlink
sys_unlink:
	jmp std_unlink
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
	xor %eax, %eax
	retq

.data
.align 8
# WSADATA (~408B on x64). Ready flag omitted: peff AV on separate .long label.
win_wsadata:
	.zero 512
.align 8
.globl win_ep_used
win_ep_used:
	.zero 16
.align 8
.globl win_ep_n
win_ep_n:
	.zero 64
.align 8
# 16 epoll sets x 128 fds (WSAPoll software epoll).
.globl win_ep_fds
win_ep_fds:
	.zero 8192
.align 8
.globl win_ep_evs
win_ep_evs:
	.zero 8192
.align 8
.globl win_ep_toks
win_ep_toks:
	.zero 16384
.align 8
# Per tu-fd: 1 if listen() succeeded (WSAPoll listen POLLIN workaround).
.global win_fd_listen
win_fd_listen:
	.zero 256
.align 8
# Per listen tu-fd: stashed SOCKET from epoll_wait accept probe (0=empty).
.global win_accept_stash
win_accept_stash:
	.zero 2048

