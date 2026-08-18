# RFC-107 D1.3: %ax is 16-bit, not a silent %rax alias. ALU must fail at parse.
.text
.globl main
main:
    add %ax, %rax
    ret
