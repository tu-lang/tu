# RFC-107 D1: unknown %reg must fail (not become a symbol named %r99).
.text
.globl main
main:
    mov %r99, %rax
    ret
