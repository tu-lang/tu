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

