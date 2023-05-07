
mov.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	88 c3                	mov    %al,%bl
   2:	89 c1                	mov    %eax,%ecx
   4:	48 89 c1             	mov    %rax,%rcx
   7:	4d 89 c1             	mov    %r8,%r9
   a:	4c 89 c0             	mov    %r8,%rax
   d:	49 89 c0             	mov    %rax,%r8
  10:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
  17:	48 c7 c0 2c 01 00 00 	mov    $0x12c,%rax
  1e:	49 c7 c1 64 00 00 00 	mov    $0x64,%r9

0000000000000025 <r1>:
  25:	88 07                	mov    %al,(%rdi)
  27:	66 89 07             	mov    %ax,(%rdi)
  2a:	28 07                	sub    %al,(%rdi)
  2c:	00 07                	add    %al,(%rdi)
  2e:	48 89 07             	mov    %rax,(%rdi)
  31:	48 89 47 0a          	mov    %rax,0xa(%rdi)
  35:	48 89 87 82 00 00 00 	mov    %rax,0x82(%rdi)
  3c:	48 8b 07             	mov    (%rdi),%rax
  3f:	48 8b 47 0a          	mov    0xa(%rdi),%rax
  43:	48 8b 87 82 00 00 00 	mov    0x82(%rdi),%rax

000000000000004a <bigim>:
  4a:	48 ba ab 62 51 4e 18 	movabs $0xa4f881184e5162ab,%rdx
  51:	81 f8 a4 
  54:	48 c7 c0 ff ff ff ff 	mov    $0xffffffffffffffff,%rax
  5b:	48 be 68 0e ac cc 33 	movabs $0xc5031b33ccac0e68,%rsi
  62:	1b 03 c5 
  65:	48 c7 c0 ff ff ff 7f 	mov    $0x7fffffff,%rax
  6c:	48 ba 1a 85 a6 d3 27 	movabs $0xe061827d3a6851a,%rdx
  73:	18 06 0e 
  76:	48 c7 c0 00 00 00 80 	mov    $0xffffffff80000000,%rax

000000000000007d <r4>:
  7d:	b8 00 00 00 00       	mov    $0x0,%eax
  82:	bb 00 00 00 00       	mov    $0x0,%ebx
