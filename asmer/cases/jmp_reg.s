l.jmp:
    jmp *%rax
    jmp *%rcx
    jmp *%r10
    jmp l.1
l.1:
    mov $1, %rax
