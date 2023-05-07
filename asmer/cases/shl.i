
shl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	d3 e0                	shl    %cl,%eax
   2:	d3 e7                	shl    %cl,%edi
   4:	d2 e5                	shl    %cl,%ch
   6:	d2 e7                	shl    %cl,%bh
   8:	48 d3 e0             	shl    %cl,%rax
   b:	48 d3 e1             	shl    %cl,%rcx
   e:	48 d3 e4             	shl    %cl,%rsp
  11:	48 d3 e7             	shl    %cl,%rdi
  14:	49 d3 e0             	shl    %cl,%r8

0000000000000017 <im>:
  17:	48 c1 e0 00          	shl    $0x0,%rax
  1b:	48 c1 e7 00          	shl    $0x0,%rdi
  1f:	49 c1 e0 64          	shl    $0x64,%r8
  23:	c1 e0 64             	shl    $0x64,%eax
  26:	48 c1 e0 c0          	shl    $0xc0,%rax
