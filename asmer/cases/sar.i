
sar.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <rim>:
   0:	48 c1 f8 64          	sar    $0x64,%rax
   4:	49 c1 f9 64          	sar    $0x64,%r9
   8:	c1 f8 64             	sar    $0x64,%eax
   b:	c1 fd 64             	sar    $0x64,%ebp
   e:	c1 fc 64             	sar    $0x64,%esp

0000000000000011 <r4>:
  11:	d3 f8                	sar    %cl,%eax
  13:	d3 fd                	sar    %cl,%ebp
  15:	d3 fc                	sar    %cl,%esp
  17:	d3 ff                	sar    %cl,%edi

0000000000000019 <r8>:
  19:	48 d3 f8             	sar    %cl,%rax
  1c:	49 d3 f8             	sar    %cl,%r8
  1f:	48 d3 fd             	sar    %cl,%rbp
  22:	48 d3 fc             	sar    %cl,%rsp
