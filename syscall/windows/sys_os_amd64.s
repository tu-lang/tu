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
