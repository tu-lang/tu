
r8d.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	41 89 c0             	mov    %eax,%r8d
   3:	44 89 c0             	mov    %r8d,%eax
   6:	45 89 ca             	mov    %r9d,%r10d
   9:	44 01 c0             	add    %r8d,%eax
   c:	44 39 c0             	cmp    %r8d,%eax
   f:	c3                   	ret

