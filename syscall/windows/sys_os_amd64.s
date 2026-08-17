.text
.global os__getpid
os__getpid:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	call GetCurrentProcessId
	mov %rbp, %rsp
	pop %rbp
	retq

.global os__fork
os__fork:
	mov $-38, %rax
	retq

.global os__wait4
os__wait4:
	mov $-38, %rax
	retq

# Thin process-spawn thunks (RFC-107 dialect: marshal + call, no logic).
# CreateProcessA(NULL, cmd, NULL, NULL, TRUE, 0, NULL, NULL, si, pi)
.global os_win_create_process
os_win_create_process:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $96, %rsp
	mov %rdx, %rax
	mov %rdi, %rdx
	xor %ecx, %ecx
	xor %r8d, %r8d
	xor %r9d, %r9d
	movq $1, 32(%rsp)
	movq $0, 40(%rsp)
	movq $0, 48(%rsp)
	movq $0, 56(%rsp)
	mov %rsi, 64(%rsp)
	mov %rax, 72(%rsp)
	call CreateProcessA
	mov %rbp, %rsp
	pop %rbp
	retq

# WaitForSingleObject(handle, INFINITE)
.global os_win_wait_object
os_win_wait_object:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	mov $-1, %edx
	call WaitForSingleObject
	mov %rbp, %rsp
	pop %rbp
	retq

# GetExitCodeProcess(handle, out_code_ptr)
.global os_win_exit_code
os_win_exit_code:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	mov %rsi, %rdx
	call GetExitCodeProcess
	mov %rbp, %rsp
	pop %rbp
	retq

# CloseHandle(handle)
.global os_win_close_handle
os_win_close_handle:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call CloseHandle
	mov %rbp, %rsp
	pop %rbp
	retq

# Path-based FindFirstFileA (Tu SysV: rdi=pattern only).
# Name is written to win_find_name; caller reads via os_win_find_name.
.global os_win_find_first
os_win_find_first:
	push %rbp
	mov %rsp, %rbp
	push %rbx
	and $-16, %rsp
	sub $384, %rsp
	mov %rdi, %rcx
	lea 32(%rsp), %rdx
	call FindFirstFileA
	cmp $-1, %rax
	je wff_fail
	lea 76(%rsp), %rsi
	lea win_find_name(%rip), %rdi
	mov $255, %edx
wff_cpy:
	cmp $0, %edx
	je wff_cpy_done
	movb (%rsi), %cl
	movb %cl, (%rdi)
	cmp $0, %cl
	je wff_ok
	add $1, %rsi
	add $1, %rdi
	sub $1, %edx
	jmp wff_cpy
wff_cpy_done:
	movb $0, (%rdi)
wff_ok:
	jmp wff_out
wff_fail:
	xor %eax, %eax
wff_out:
	lea -8(%rbp), %rsp
	pop %rbx
	pop %rbp
	retq

.global os_win_find_next
os_win_find_next:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $384, %rsp
	mov %rdi, %rcx
	lea 32(%rsp), %rdx
	call FindNextFileA
	cmp $0, %eax
	je wfn_fail
	lea 76(%rsp), %rsi
	lea win_find_name(%rip), %rdi
	mov $255, %edx
wfn_cpy:
	cmp $0, %edx
	je wfn_cpy_done
	movb (%rsi), %cl
	movb %cl, (%rdi)
	cmp $0, %cl
	je wfn_ok
	add $1, %rsi
	add $1, %rdi
	sub $1, %edx
	jmp wfn_cpy
wfn_cpy_done:
	movb $0, (%rdi)
wfn_ok:
	mov $1, %eax
	jmp wfn_out
wfn_fail:
	xor %eax, %eax
wfn_out:
	mov %rbp, %rsp
	pop %rbp
	retq

.global os_win_find_close
os_win_find_close:
	push %rbp
	mov %rsp, %rbp
	and $-16, %rsp
	sub $32, %rsp
	mov %rdi, %rcx
	call FindClose
	mov %rbp, %rsp
	pop %rbp
	retq

.global os_win_find_name
os_win_find_name:
	lea win_find_name(%rip), %rax
	retq

.data
.align 8
win_find_name:
	.zero 256
