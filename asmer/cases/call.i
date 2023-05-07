
call.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <l.call>:
   0:	e8 00 00 00 00       	callq  5 <l.call+0x5>
   5:	e8 0a 00 00 00       	callq  14 <l.1>
   a:	ff d0                	callq  *%rax
   c:	41 ff d2             	callq  *%r10
   f:	e8 ec ff ff ff       	callq  0 <l.call>

0000000000000014 <l.1>:
  14:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
