
xadd.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r8>:
   0:	48 0f c1 08          	xadd   %rcx,(%rax)
   4:	49 0f c1 09          	xadd   %rcx,(%r9)
   8:	4c 0f c1 c9          	xadd   %r9,%rcx
   c:	4d 0f c1 c8          	xadd   %r9,%r8

0000000000000010 <r4>:
  10:	0f c1 08             	xadd   %ecx,(%rax)
  13:	41 0f c1 09          	xadd   %ecx,(%r9)
  17:	0f c1 ca             	xadd   %ecx,%edx
