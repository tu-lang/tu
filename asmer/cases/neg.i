
neg.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	f7 d8                	neg    %eax
   2:	48 f7 d8             	neg    %rax
   5:	49 f7 d8             	neg    %r8
   8:	ff c0                	inc    %eax
   a:	48 ff c0             	inc    %rax
   d:	ff cf                	dec    %edi
   f:	c3                   	ret

