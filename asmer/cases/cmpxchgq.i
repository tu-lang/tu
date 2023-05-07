
cmpxchgq.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r8>:
   0:	48 0f b1 11          	cmpxchg %rdx,(%rcx)
   4:	48 0f b1 c1          	cmpxchg %rax,%rcx
   8:	49 0f b1 c1          	cmpxchg %rax,%r9
   c:	4c 0f b1 c7          	cmpxchg %r8,%rdi
  10:	4d 0f b1 c1          	cmpxchg %r8,%r9
