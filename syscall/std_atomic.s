.text
.global std_atomic_cas64  
std_atomic_cas64:
    mov     %rdi , %rcx
    mov     %rsi , %rax
    lock 
    cmpxchg %rdx,(%rcx)
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

.global std_atomic_store32
std_atomic_store32:
    mov     %rdi , %rax
    mov     %esi , %ecx
    xchg    %ecx , (%rax)
    retq

.global std_atomic_xadd
std_atomic_xadd:
    mov     %rdi , %rax
    mov     %esi , %ecx
    lock 
    xadd    %ecx , (%rax)
    mov    (%rax) ,%eax
    retq

.global std_atomic_xadd64
std_atomic_xadd64:
    mov     %rdi , %rax
    mov     %rsi , %rcx
    lock 
    xadd    %rcx , (%rax)
    mov    (%rax) ,%rax
    retq



