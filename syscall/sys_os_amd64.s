.text
.global os__getpid  
os__getpid:
	mov    $39,%rax
	syscall
	retq   
.global os__fork
os__fork:
	mov $57 , %rax
	syscall
	retq
.global os__wait4
os__wait4:
	mov $61 , %rax
	syscall
	retq

