
shr.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r1r2>:
   0:	d3 e8                	shr    %cl,%eax
   2:	d3 ea                	shr    %cl,%edx

0000000000000004 <r1r8>:
   4:	48 d3 e8             	shr    %cl,%rax
   7:	49 d3 e9             	shr    %cl,%r9

000000000000000a <im>:
   a:	48 c1 e8 00          	shr    $0x0,%rax
   e:	48 c1 ef 00          	shr    $0x0,%rdi
  12:	49 c1 e8 64          	shr    $0x64,%r8
  16:	c1 e8 64             	shr    $0x64,%eax
  19:	48 c1 e8 c0          	shr    $0xc0,%rax
