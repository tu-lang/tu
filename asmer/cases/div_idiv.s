ldiv:
    div %al
    div %bh
    div %eax
    div %rax
    div %edi
    div %rdi
    div %r8
    div %rax
lidiv:
    idiv %al
    idiv %bh
    idiv %eax
    idiv %rax
    idiv %edi
    idiv %rdi
    idiv %r8
    div %rax
    
lidivq:
    idivq %rax
    idivq %rdi
    idivq %r8
    div %rax
