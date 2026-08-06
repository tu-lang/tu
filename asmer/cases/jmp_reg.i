
jmp_reg.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <l.jmp>:
   0:	48 ff e0             	rex.W jmpq *%rax
   3:	48 ff e1             	rex.W jmpq *%rcx
   6:	49 ff e2             	rex.WB jmpq *%r10
   9:	e9 00 00 00 00       	jmpq   e <l.1>

000000000000000e <l.1>:
   e:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
