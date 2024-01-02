rr:
    mov    %rdx , %r12
    mov    %rcx , %r13
    mov    %r8 , %r14
    mov    %rsi , %rsp
    mov    %r12 , %rdi
    mov    %r13 , %rdi
    mov    %r14 , %rcx
    mov    %r15 , %rdx
imr:
    mov    $0 , %rdx
    mov    $0 , %r10
    mov    $100 , %r14
    mov    $0 , %r8
    mov    $56, %rax
    callq  *%r13