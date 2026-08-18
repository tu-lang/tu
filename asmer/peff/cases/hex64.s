# 64-bit hex immediates / .quad.
.global hex64_data
hex64_data:
    .quad 0xFFFFFFFFFFFFFFFF
    .quad 0x8000000000000000
    .quad 0x1

.global hex64_imm
hex64_imm:
    movabsq $0xFFFFFFFFFFFFFFFF, %rax
    movabsq $0x8000000000000000, %rdx
    ret
