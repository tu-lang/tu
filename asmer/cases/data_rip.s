# RFC-107 D3.2: 32-bit RIP-relative load/store of an isolated .long.
# Must not encode as B8 imm32 (mov $0,%eax) and must emit a reloc hole.
main:
    movl ready(%rip), %eax
    mov ready(%rip), %eax
    movl %eax, ready(%rip)
    lea ready(%rip), %rax
    ret
.data
ready:
    .long 0x12345678
