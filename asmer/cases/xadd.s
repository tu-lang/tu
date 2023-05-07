r8:
    xadd %rcx , (%rax)
    xadd %rcx , (%r9)
    xadd %r9   , %rcx
    xadd %r9   , %r8
r4:
    xadd %ecx , (%rax)
    xadd %ecx , (%r9)
    xadd %ecx , %edx
