r8:
    xchg %rax , %rdi
    xchg %rcx , %rdi
    xchg %rax , %r9
    xchg %r9 , %rdx
    xchg %r9 , %r8
    xchg %rcx , (%rdx)
r4:
    xchg %ecx , (%rax)
    xchg %ecx , (%r9)
    xchg %ecx , %edx
