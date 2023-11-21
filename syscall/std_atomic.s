.text
.global std_atomic_cas64  
std_atomic_cas64:
    mov     %rdi , %rcx
    mov     %rsi , %rax
    lock 
    cmpxchgq %rdx,(%rcx)
    sete    %al
    movzb   %al, %rax
	retq

.global std_atomic_cas  
std_atomic_cas:
    mov     %rdi , %rcx
    mov     %esi , %eax
    lock 
    cmpxchgl %edx,(%rcx)
    sete    %al
    movzb   %al, %rax
	retq

.global std_atomic_xchg
std_atomic_xchg:
    mov     %rdi , %rax
    mov     %esi , %ecx
    xchg    %ecx , (%rax)
    movsxd  %ecx,  %rax
    retq

.global std_atomic_store
std_atomic_store:
    mov     %rdi , %rax
    mov     %esi , %ecx
    xchg    %ecx , (%rax)
    retq

.global std_atomic_store64
std_atomic_store64:
    mov     %rdi , %rax
    mov     %rsi , %rcx
    xchg    %rcx , (%rax)
    retq

.global std_atomic_xadd
std_atomic_xadd:
    mov     %rdi , %rdx  
    mov     %esi , %eax  
    lock 
    xadd    %eax , (%rdx)
    add     %ecx , %eax
    ret

.global std_atomic_xadd64
std_atomic_xadd64:
    mov     %rdi , %rax
    mov     %rsi , %rcx
    lock 
    xadd    %rcx , (%rax)
    mov    (%rax) ,%rax
    retq



