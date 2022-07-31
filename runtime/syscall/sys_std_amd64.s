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

.globl std_sleep
std_sleep:
     sub    $0x18,%rsp
     add    $8,%rdi
     mov    (%rdi),%rax
     imul   $1000000,%rax,%rax
     mov    %rax,0x20(%rsp)
     mov    %rbp,0x10(%rsp)
     lea    0x10(%rsp),%rbp
     mov    $0x0,%edx
     mov    0x20(%rsp),%eax
     mov    $0xf4240,%ecx
     div    %ecx
     mov    %rax,(%rsp)
     mov    $0x3e8,%eax
     mul    %edx
     mov    %rax,0x8(%rsp)
     mov    $0x0,%edi
     mov    $0x0,%esi
     mov    $0x0,%edx
     mov    $0x0,%r10d
     mov    %rsp,%r8
     mov    $0x0,%r9d
     mov    $0x10e,%eax
     syscall
     mov    0x10(%rsp),%rbp
     add    $0x18,%rsp
     retq
.globl std_usleep
std_usleep:
     sub    $0x18,%rsp
     add    $8,%rdi
     mov    (%rdi),%rdi
     mov    %rdi,0x20(%rsp)
     mov    %rbp,0x10(%rsp)
     lea    0x10(%rsp),%rbp
     mov    $0x0,%edx
     mov    0x20(%rsp),%eax
     mov    $0xf4240,%ecx
     div    %ecx
     mov    %rax,(%rsp)
     mov    $0x3e8,%eax
     mul    %edx
     mov    %rax,0x8(%rsp)
     mov    $0x0,%edi
     mov    $0x0,%esi
     mov    $0x0,%edx
     mov    $0x0,%r10d
     mov    %rsp,%r8
     mov    $0x0,%r9d
     mov    $0x10e,%eax
     syscall
     mov    0x10(%rsp),%rbp
     add    $0x18,%rsp
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

