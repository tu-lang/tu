
jmp.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	e9 05 00 00 00                	jmp    4 <test>
   2:	e9 00 00 00 00                	jmp    4 <test>

0000000000000004 <test>:
   4:	e9 f1 ff ff ff                	jmp    0 <main>
   6:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
   d:	e9 00 00 00 00       	jmpq   12 <test+0xe>
  12:	e9 85 00 00 00       	jmpq   9c <long_end>

0000000000000017 <long_jmp>:
  17:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
  1e:	48 c7 c0 02 00 00 00 	mov    $0x2,%rax
  25:	48 c7 c0 03 00 00 00 	mov    $0x3,%rax
  2c:	48 c7 c0 04 00 00 00 	mov    $0x4,%rax
  33:	48 c7 c0 05 00 00 00 	mov    $0x5,%rax
  3a:	48 c7 c0 06 00 00 00 	mov    $0x6,%rax
  41:	48 c7 c0 07 00 00 00 	mov    $0x7,%rax
  48:	48 c7 c0 08 00 00 00 	mov    $0x8,%rax
  4f:	48 c7 c0 09 00 00 00 	mov    $0x9,%rax
  56:	48 c7 c0 0a 00 00 00 	mov    $0xa,%rax
  5d:	48 c7 c0 0b 00 00 00 	mov    $0xb,%rax
  64:	48 c7 c0 0c 00 00 00 	mov    $0xc,%rax
  6b:	48 c7 c0 0d 00 00 00 	mov    $0xd,%rax
  72:	48 c7 c0 0e 00 00 00 	mov    $0xe,%rax
  79:	48 c7 c0 0f 00 00 00 	mov    $0xf,%rax
  80:	48 c7 c0 10 00 00 00 	mov    $0x10,%rax
  87:	48 c7 c0 11 00 00 00 	mov    $0x11,%rax
  8e:	48 c7 c0 12 00 00 00 	mov    $0x12,%rax
  95:	48 c7 c0 13 00 00 00 	mov    $0x13,%rax

000000000000009c <long_end>:
  9c:	48 c7 c0 14 00 00 00 	mov    $0x14,%rax
  a3:	e9 6f ff ff ff       	jmpq   17 <long_jmp>
