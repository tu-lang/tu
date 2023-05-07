
je.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	83 f8 00             	cmp    $0x0,%eax
   3:	0f 84 09 00 00 00                	je     e <main+0xe>
   5:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
   c:	89 c3                	mov    %eax,%ebx
   e:	83 f8 01             	cmp    $0x1,%eax
  11:	0f 84 f5 ff ff ff                	je     c <main+0xc>
  13:	0f 84 8b 00 00 00    	je     a0 <L2>
  19:	0f 84 00 00 00 00                	je     1b <L1>

000000000000001b <L1>:
  1b:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
  22:	48 c7 c0 02 00 00 00 	mov    $0x2,%rax
  29:	48 c7 c0 03 00 00 00 	mov    $0x3,%rax
  30:	48 c7 c0 04 00 00 00 	mov    $0x4,%rax
  37:	48 c7 c0 05 00 00 00 	mov    $0x5,%rax
  3e:	48 c7 c0 06 00 00 00 	mov    $0x6,%rax
  45:	48 c7 c0 07 00 00 00 	mov    $0x7,%rax
  4c:	48 c7 c0 08 00 00 00 	mov    $0x8,%rax
  53:	48 c7 c0 09 00 00 00 	mov    $0x9,%rax
  5a:	48 c7 c0 0a 00 00 00 	mov    $0xa,%rax
  61:	48 c7 c0 0b 00 00 00 	mov    $0xb,%rax
  68:	48 c7 c0 0c 00 00 00 	mov    $0xc,%rax
  6f:	48 c7 c0 0d 00 00 00 	mov    $0xd,%rax
  76:	48 c7 c0 0e 00 00 00 	mov    $0xe,%rax
  7d:	48 c7 c0 0f 00 00 00 	mov    $0xf,%rax
  84:	48 c7 c0 10 00 00 00 	mov    $0x10,%rax
  8b:	48 c7 c0 11 00 00 00 	mov    $0x11,%rax
  92:	48 c7 c0 12 00 00 00 	mov    $0x12,%rax
  99:	48 c7 c0 13 00 00 00 	mov    $0x13,%rax

00000000000000a0 <L2>:
  a0:	48 c7 c0 14 00 00 00 	mov    $0x14,%rax
