# RFC-107 D1.3: (%ax) is not a 64-bit memory base.
.text
.globl main
main:
    mov (%ax), %rax
    ret
