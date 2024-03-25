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
    idivq %r9
	idivq 8(%rsp)
	idivq -16(%rsp)
	idivq 8(%rbp)
	idivq -16(%rbp)
    div %rax
    div %r9
	idivq (%rax)
	idivq 8(%rax)
	idivq (%r9)
	idivq -16(%r9)