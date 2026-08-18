# RFC-107 D3.2: runtime load/store of isolated .long/.byte around a blob.
# ExitProcess so the PE stub cannot swallow main_main's return.

.text
.globl main_main
main_main:
    movl ready_before(%rip), %eax
    cmpl $0x11111111, %eax
    jne fail

    movl ready_after(%rip), %eax
    cmpl $0x12345678, %eax
    jne fail

    lea ready_after(%rip), %rax
    cmpl $0x12345678, (%rax)
    jne fail
    movl $1, (%rax)
    movl ready_after(%rip), %eax
    cmpl $1, %eax
    jne fail

    movzbl flag_byte(%rip), %eax
    cmpl $0xAA, %eax
    jne fail
    lea flag_byte(%rip), %rax
    movb $0x55, (%rax)
    movzbl flag_byte(%rip), %eax
    cmpl $0x55, %eax
    jne fail

    xor %ecx, %ecx
    call ExitProcess
fail:
    movl $2, %ecx
    call ExitProcess

.globl main_init.0
main_init.0:
    ret

.data
.align 8
.globl ready_before
ready_before:
    .long 0x11111111
blob:
    .zero 512
.align 8
.globl ready_after
ready_after:
    .long 0x12345678
.globl flag_byte
flag_byte:
    .byte 0xAA
