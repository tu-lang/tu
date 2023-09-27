.text
.global std_open  
std_open:
	mov    $0x2,%rax
	syscall
	retq   

.global std_read  
std_read:
	mov    $0,%rax
	syscall
	retq   

.global std_close  
std_close:
	mov    $0x3,%rax
	syscall
	retq  

.global std_write  
std_write:
	mov    $0x1,%rax
	syscall
	retq   

.global std_seek
std_seek:
	mov $0x8,%rax
	syscall
	retq
.global std_die
std_die:
	mov $60,%rax
	syscall
	retq
.global std_brk
std_brk:
    mov $12,%rax
    syscall
    retq

.globl std_nanosleep
std_nanosleep:
     mov $35 , %rax
     syscall
     retq

.globl std_getdents
std_getdents:
     mov $78,%rax
     syscall
     retq

.globl std_stat
std_stat:
     mov $4 , %rax
     syscall
     retq

.globl std_fstat
std_fstat:
     mov $5 , %rax
     syscall
     retq

.globl std_lstat
std_lstat:
     mov $6 , %rax
     syscall
     retq

.globl std_execve
std_execve:
     mov $59 , %rax
     syscall
     retq

.globl std_time
std_time:
     mov $201 , %rax
     syscall
     retq

.globl std_clock_gettime
std_clock_gettime:
     mov $228 , %rax
     syscall
     retq

.globl std_sigreturn
std_sigreturn:
     mov $15 , %rax
     syscall
     retq

.globl std_rt_sigaction
std_rt_sigaction:
     mov %rcx, %r10
     mov $13 , %rax
     syscall
     retq

.globl std_mmap
std_mmap:
     mov %rcx, %r10
     mov $9 , %rax
     syscall
     retq
     
.globl std_madvise
std_madvise:
     mov $28 , %rax
     syscall
     retq

.globl std_munmap
std_munmap:
     mov $11 , %rax
     syscall
     retq
.globl std_segsegvrecv
std_segsegvrecv:
     push %rdx
     push %rsi
     push %rdi
     call runtime_segsegv_handler
     add $24, %rsp
     retq
.globl std_readlink
std_readlink:
     mov $89 , %rax
     syscall
     retq


