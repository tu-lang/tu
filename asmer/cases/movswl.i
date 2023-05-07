
movswl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <rm2r>:
   0:	0f bf 00             	movswl (%rax),%eax
   3:	0f bf 18             	movswl (%rax),%ebx
   6:	41 0f bf 00          	movswl (%r8),%eax
   a:	41 0f bf 20          	movswl (%r8),%esp
   e:	41 0f bf 60 0a       	movswl 0xa(%r8),%esp
  13:	41 0f bf a0 8c 00 00 	movswl 0x8c(%r8),%esp
  1a:	00 

000000000000001b <r2r>:
  1b:	0f bf c0             	movswl %ax,%eax
