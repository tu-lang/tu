# RFC-107: KW_CMPL — 32-bit compare to memory (no REX.W / addq mis-encode).
cmpl_mem:
    cmpl $1, (%rax)
    cmpl $1, 16(%rax)
    cmpl $1, (%r12)
    cmpl $1, 16(%r12)
