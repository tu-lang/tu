# %r8d–%r15d 32-bit extended regs (RFC-107)
main:
    mov %eax, %r8d
    mov %r8d, %eax
    mov %r9d, %r10d
    add %r8d, %eax
    cmp %r8d, %eax
    ret
