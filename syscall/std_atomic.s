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

