# RFC-107 D1: unknown mnemonic must fail at assemble time (not become a COFF undef).
.text
.globl main
main:
    not_a_real_insn %rax
    ret
