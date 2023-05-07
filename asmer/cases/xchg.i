
xchg.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r8>:
   0:	48 97                	xchg   %rax,%rdi
   2:	48 87 cf             	xchg   %rcx,%rdi
   5:	49 91                	xchg   %rax,%r9
   7:	4c 87 ca             	xchg   %r9,%rdx
   a:	4d 87 c8             	xchg   %r9,%r8
   d:	48 87 0a             	xchg   %rcx,(%rdx)

0000000000000010 <r4>:
  10:	87 08                	xchg   %ecx,(%rax)
  12:	41 87 09             	xchg   %ecx,(%r9)
  15:	87 ca                	xchg   %ecx,%edx
