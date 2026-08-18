# RFC-107 D3: disp8(%r12) needs SIB; (%r13) must not be RIP-relative.
main:
    mov %rax, 1(%r12)
    mov %rax, (%r12)
    mov %rax, 1(%r13)
    mov %rax, (%r13)
    mov 8(%r12), %rcx
    mov 8(%r13), %rcx
    movq $0, 1(%r12)
    movq $0, 1(%rsp)
    movq $0, (%rbp)
    ret
