
movzwl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <rm2r>:
   0:	0f b7 00             	movzwl (%rax),%eax
   3:	48 0f b7 38          	movzwq (%rax),%rdi
   7:	41 0f b7 00          	movzwl (%r8),%eax
   b:	41 0f b7 40 0a       	movzwl 0xa(%r8),%eax
  10:	4d 0f b7 08          	movzwq (%r8),%r9
  14:	4d 0f b7 88 8c 00 00 	movzwq 0x8c(%r8),%r9
  1b:	00 

000000000000001c <r2r>:
  1c:	0f b7 c0             	movzwl %ax,%eax
  1f:	48 0f b7 c0          	movzwq %ax,%rax
