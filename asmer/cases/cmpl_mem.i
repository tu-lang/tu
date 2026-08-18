
cmpl_mem.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <cmpl_mem>:
   0:   83 38 01                cmpl   $0x1,(%rax)
   4:   83 78 10 01             cmpl   $0x1,0x10(%rax)
   9:   41 83 3c 24 01          cmpl   $0x1,(%r12)
   e:   41 83 7c 24 10 01       cmpl   $0x1,0x10(%r12)
