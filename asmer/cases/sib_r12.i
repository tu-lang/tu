
sib_r12.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	49 89 44 24 01       	mov    %rax,0x1(%r12)
   5:	49 89 04 24          	mov    %rax,(%r12)
   9:	49 89 45 01          	mov    %rax,0x1(%r13)
   d:	49 89 45 00          	mov    %rax,(%r13)
  11:	49 8b 4c 24 08       	mov    0x8(%r12),%rcx
  16:	49 8b 4d 08          	mov    0x8(%r13),%rcx
  1a:	49 c7 44 24 01 00 00 	movq   $0x0,0x1(%r12)
  21:	00 00 
  23:	48 c7 44 24 01 00 00 	movq   $0x0,0x1(%rsp)
  2a:	00 00 
  2c:	48 c7 45 00 00 00 00 	movq   $0x0,(%rbp)
  33:	00 
  34:	c3                   	ret

