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
# Thin trampoline: Tu stack ABI ? push arg, then call runtime_win_wsa_errno_neg.
.globl win_wsa_errno_neg
win_wsa_errno_neg:
	movsxd %edi, %rax
	push %rax
	call runtime_win_wsa_errno_neg
	add $8, %rsp
	ret

win_wsa_fail:
	call WSAGetLastError
	mov %eax, %edi
	call win_wsa_errno_neg
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
	sub $32, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	call win_fd_get
	cmp $0, %rax
	je sb_err
	mov %rax, %rbx
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
	sub $32, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	call win_fd_get
	cmp $0, %rax
	je scn_err
	mov %rax, %rbx
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
	and $-16, %rsp
	sub $32, %rsp
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
	xor %eax, %eax
	jmp sln_out
sln_err:
	mov $-9, %rax
sln_out:
	lea -8(%rbp), %rsp
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
	and $-16, %rsp
	sub $48, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
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
	# Skip AF_INET6 family rewrite: peff asmer rejects/misencodes 1(%r12) stores.
sa4_nb:
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
	lea -32(%rbp), %rsp
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

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
	sub $160, %rsp
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
	mov %rax, 56(%rsp)
	cmp $0, %r15
	je ssto_call
	movzbl (%r15), %eax
	cmp $10, %eax
	jne ssto_call
	# Copy sockaddr to stack and rewrite AF_INET6.
	xor %ecx, %ecx
ssto_cpy:
	cmp %rbx, %rcx
	jge ssto_cpy_done
	mov %r15, %rsi
	add %rcx, %rsi
	movzbl (%rsi), %edx
	lea 64(%rsp), %rdi
	add %rcx, %rdi
	movb %dl, (%rdi)
	add $1, %ecx
	jmp ssto_cpy
ssto_cpy_done:
	movb $23, 64(%rsp)
	movb $0, 65(%rsp)
	lea 64(%rsp), %r15
ssto_call:
	mov 56(%rsp), %rcx
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
	# Skip AF_INET6 rewrite (avoid 1(%r15) displacement form).
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
	# sockaddr_in 127.0.0.1:0
	lea 48(%rsp), %rax
	movq $0, (%rax)
	movq $0, 8(%rax)
	movb $2, (%rax)
	movb $0, 1(%rax)
	movb $127, 4(%rax)
	movb $0, 5(%rax)
	movb $0, 6(%rax)
	movb $1, 7(%rax)
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

.global sys_epoll_create1
sys_epoll_create1:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	and $-16, %rsp
	sub $32, %rsp
	xor %ebx, %ebx
sec_find:
	cmp $16, %ebx
	jge sec_full
	lea win_ep_used(%rip), %rax
	add %rbx, %rax
	movzbl (%rax), %eax
	cmp $0, %eax
	je sec_got
	add $1, %ebx
	jmp sec_find
sec_got:
	lea win_ep_used(%rip), %rax
	add %rbx, %rax
	movb $1, (%rax)
	lea win_ep_n(%rip), %rax
	mov %rbx, %rcx
	shl $2, %rcx
	add %rcx, %rax
	movl $0, (%rax)
	# Placeholder handle 1; identity is win_ep_fd_of[tu_fd] = ep_idx+1.
	mov $1, %rdi
	call win_fd_alloc
	cmp $-1, %eax
	je sec_fail
	mov %eax, %eax
	mov %rax, %r12
	mov %r12, %rdi
	mov %rbx, %rsi
	call win_ep_set_fd
	mov %r12, %rax
	jmp sec_out
sec_fail:
	lea win_ep_used(%rip), %rax
	add %rbx, %rax
	movb $0, (%rax)
sec_full:
	mov $-24, %rax
sec_out:
	lea -16(%rbp), %rsp
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_epoll_ctl
sys_epoll_ctl:
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
	mov %rcx, %r14
	# rdi still epfd
	call win_ep_get_fd
	cmp $0xFF, %eax
	je sectl_err
	cmp $16, %eax
	jge sectl_err
	mov %rax, %rbx
	lea win_ep_used(%rip), %rax
	add %rbx, %rax
	movzbl (%rax), %eax
	cmp $0, %eax
	je sectl_err
	cmp $3, %r12
	je sectl_del
	cmp $1, %r12
	je sectl_add
	cmp $2, %r12
	je sectl_mod
	mov $-22, %rax
	jmp sectl_out
sectl_add:
	lea win_ep_n(%rip), %rax
	mov %rbx, %rcx
	shl $2, %rcx
	add %rcx, %rax
	mov (%rax), %eax
	mov %rax, %r15
	xor %ecx, %ecx
sectl_af:
	cmp %r15, %rcx
	jge sectl_anew
	mov %ebx, %eax
	shl $7, %eax
	add %ecx, %eax
	lea win_ep_fds(%rip), %rdx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %eax
	cmp %r13, %rax
	je sectl_aupd
	add $1, %ecx
	jmp sectl_af
sectl_anew:
	cmp $128, %r15
	jge sectl_enospc
	mov %ebx, %eax
	shl $7, %eax
	add %r15, %rax
	lea win_ep_fds(%rip), %rdx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov %r13, %rax
	mov %eax, (%rdx)
	mov (%r14), %edx
	lea win_ep_evs(%rip), %rcx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rcx
	mov %edx, (%rcx)
	mov 4(%r14), %rdx
	lea win_ep_toks(%rip), %rcx
	mov %eax, %esi
	shl $3, %esi
	add %rsi, %rcx
	mov %rdx, (%rcx)
	add $1, %r15
	lea win_ep_n(%rip), %rax
	mov %rbx, %rcx
	shl $2, %rcx
	add %rcx, %rax
	mov %r15, %rdx
	mov %edx, (%rax)
	xor %eax, %eax
	jmp sectl_out
sectl_aupd:
sectl_mod:
	xor %ecx, %ecx
	lea win_ep_n(%rip), %rax
	mov %rbx, %rdx
	shl $2, %rdx
	add %rdx, %rax
	mov (%rax), %eax
	mov %rax, %r15
sectl_mf:
	cmp %r15, %rcx
	jge sectl_enoent
	mov %ebx, %eax
	shl $7, %eax
	add %ecx, %eax
	lea win_ep_fds(%rip), %rdx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %eax
	cmp %r13, %rax
	je sectl_mdo
	add $1, %ecx
	jmp sectl_mf
sectl_mdo:
	mov (%r14), %edx
	lea win_ep_evs(%rip), %rcx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rcx
	mov %edx, (%rcx)
	mov 4(%r14), %rdx
	lea win_ep_toks(%rip), %rcx
	mov %eax, %esi
	shl $3, %esi
	add %rsi, %rcx
	mov %rdx, (%rcx)
	xor %eax, %eax
	jmp sectl_out
sectl_del:
	xor %ecx, %ecx
	lea win_ep_n(%rip), %rax
	mov %rbx, %rdx
	shl $2, %rdx
	add %rdx, %rax
	mov (%rax), %eax
	mov %rax, %r15
sectl_df:
	cmp %r15, %rcx
	jge sectl_ok0
	mov %ebx, %eax
	shl $7, %eax
	add %ecx, %eax
	lea win_ep_fds(%rip), %rdx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %eax
	cmp %r13, %rax
	je sectl_ddo
	add $1, %ecx
	jmp sectl_df
sectl_ddo:
	mov %r15, %r8
	sub $1, %r8
	mov %ebx, %eax
	shl $7, %eax
	mov %eax, %r9
	add %ecx, %eax
	add %r8, %r9
	lea win_ep_fds(%rip), %rdx
	mov %r9, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %esi
	lea win_ep_fds(%rip), %rdx
	mov %eax, %edi
	shl $2, %edi
	add %rdi, %rdx
	mov %esi, (%rdx)
	lea win_ep_evs(%rip), %rdx
	mov %r9, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %esi
	lea win_ep_evs(%rip), %rdx
	mov %eax, %edi
	shl $2, %edi
	add %rdi, %rdx
	mov %esi, (%rdx)
	lea win_ep_toks(%rip), %rdx
	mov %r9, %esi
	shl $3, %esi
	add %rsi, %rdx
	mov (%rdx), %rsi
	lea win_ep_toks(%rip), %rdx
	mov %eax, %edi
	shl $3, %edi
	add %rdi, %rdx
	mov %rsi, (%rdx)
	lea win_ep_n(%rip), %rax
	mov %rbx, %rcx
	shl $2, %rcx
	add %rcx, %rax
	mov %r8, (%rax)
sectl_ok0:
	xor %eax, %eax
	jmp sectl_out
sectl_enospc:
	mov $-24, %rax
	jmp sectl_out
sectl_enoent:
	mov $-2, %rax
	jmp sectl_out
sectl_err:
	mov $-9, %rax
sectl_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
	retq

.global sys_epoll_wait
sys_epoll_wait:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	push %r12
	push %r13
	push %r14
	push %r15
	and $-16, %rsp
	sub $2112, %rsp
	mov %rsi, %r12
	mov %rdx, %r13
	mov %rcx, %r14
	call win_ep_get_fd
	cmp $0xFF, %eax
	je sew_err
	cmp $16, %eax
	jge sew_err
	mov %rax, %rbx
	lea win_ep_used(%rip), %rax
	add %rbx, %rax
	movzbl (%rax), %eax
	cmp $0, %eax
	je sew_err
	lea win_ep_n(%rip), %rax
	mov %rbx, %rcx
	shl $2, %rcx
	add %rcx, %rax
	mov (%rax), %eax
	mov %rax, %r15
	cmp $0, %r15
	jne sew_build
	mov %r14, %rcx
	cmp $-1, %r14
	jne sew_sl
	mov $0xFFFFFFFF, %ecx
sew_sl:
	call Sleep
	xor %eax, %eax
	jmp sew_out
sew_build:
	xor %ecx, %ecx
sew_bloop:
	cmp %r15, %rcx
	jge sew_poll
	mov %ebx, %eax
	shl $7, %eax
	add %ecx, %eax
	lea win_ep_fds(%rip), %rdx
	mov %eax, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %edi
	push %rax
	push %rcx
	call win_fd_get
	pop %rcx
	pop %r8
	mov %rcx, %rdx
	shl $4, %rdx
	lea 64(%rsp), %r9
	add %rdx, %r9
	mov %rax, (%r9)
	lea win_ep_evs(%rip), %rdx
	mov %r8, %esi
	shl $2, %esi
	add %rsi, %rdx
	mov (%rdx), %eax
	xor %edi, %edi
	mov %eax, %edx
	and $0x1, %edx
	cmp $0, %edx
	je sew_po
	add $0x100, %edi
sew_po:
	mov %eax, %edx
	and $0x4, %edx
	cmp $0, %edx
	je sew_ps
	add $0x10, %edi
sew_ps:
	mov %edi, %eax
	lea 8(%r9), %rsi
	movb %al, (%rsi)
	shr $8, %eax
	movb %al, 1(%rsi)
	movb $0, 2(%rsi)
	movb $0, 3(%rsi)
	add $1, %ecx
	jmp sew_bloop
sew_poll:
	# save ep_idx; r14 becomes out-count after poll
	mov %rbx, 56(%rsp)
	lea 64(%rsp), %rcx
	mov %r15, %rdx
	mov %r14, %r8
	call WSAPoll
	cmp $-1, %eax
	je sew_wsa
	xor %ecx, %ecx
	xor %r14, %r14
sew_pack:
	cmp %r15, %rcx
	jge sew_done
	cmp %r13, %r14
	jge sew_done
	mov %rcx, %rdx
	shl $4, %rdx
	lea 64(%rsp), %r9
	add %rdx, %r9
	# WSAPOLLFD.revents is a 16-bit SHORT at +10. POLLIN=0x0100 lives in the
	# high byte ? reading only the low byte drops all readable events (UDP hang).
	movzwl 10(%r9), %eax
	cmp $0, %eax
	je sew_pn
	xor %edi, %edi
	mov %eax, %edx
	# POLLIN = POLLRDNORM|POLLRDBAND (0x0100|0x0200)
	and $0x300, %edx
	cmp $0, %edx
	je sew_pq
	add $0x1, %edi
sew_pq:
	mov %eax, %edx
	and $0x10, %edx
	cmp $0, %edx
	je sew_pr
	add $0x4, %edi
sew_pr:
	mov %eax, %edx
	and $0x1, %edx
	cmp $0, %edx
	je sew_ph
	add $0x8, %edi
sew_ph:
	mov %eax, %edx
	and $0x2, %edx
	cmp $0, %edx
	je sew_pw
	add $0x10, %edi
sew_pw:
	mov %r14, %rax
	mov %rax, %rdx
	shl $3, %rax
	shl $2, %rdx
	add %rdx, %rax
	add %r12, %rax
	mov %edi, (%rax)
	mov 56(%rsp), %edx
	shl $7, %edx
	add %ecx, %edx
	lea win_ep_toks(%rip), %r8
	mov %edx, %esi
	shl $3, %esi
	add %rsi, %r8
	mov (%r8), %r8
	mov %r8, 4(%rax)
	add $1, %r14
sew_pn:
	add $1, %ecx
	jmp sew_pack
sew_done:
	mov %r14, %rax
	jmp sew_out
sew_wsa:
	call win_wsa_fail
	jmp sew_out
sew_err:
	mov $-9, %rax
sew_out:
	lea -40(%rbp), %rsp
	pop %r15
	pop %r14
	pop %r13
	pop %r12
	pop %rbx
	pop %rbp
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
win_ep_used:
	.zero 16
.align 8
win_ep_n:
	.zero 64
.align 8
# 16 epoll sets x 128 fds (WSAPoll software epoll).
win_ep_fds:
	.zero 8192
.align 8
win_ep_evs:
	.zero 8192
.align 8
win_ep_toks:
	.zero 16384

