main:
    cmp $0,%eax
    jg .L.TRUE.007
    mov $1, %rax
.L.TRUE.006:
    mov %eax,%ebx
.L.TRUE.007:
    cmp $1,%eax
    jg .L.TRUE.006
