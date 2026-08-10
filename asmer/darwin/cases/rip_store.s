# RIP-relative store must use opcode 0x89 (not load 0x8b).
.text
.globl _main
_main:
	mov $0x42, %rax
	mov %rax, slot(%rip)
	mov slot(%rip), %rdi
	mov $0x2000001, %rax
	syscall
.data
.align 8
slot:
	.quad 0
