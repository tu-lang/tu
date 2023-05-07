
sub.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <imr>:
   0:	48 83 ec 00          	sub    $0x0,%rsp
   4:	48 83 ed 64          	sub    $0x64,%rbp
   8:	48 83 ef 64          	sub    $0x64,%rdi
   c:	83 ef 64             	sub    $0x64,%edi
   f:	49 83 e9 64          	sub    $0x64,%r9

0000000000000013 <r4>:
  13:	29 f8                	sub    %edi,%eax
  15:	29 de                	sub    %ebx,%esi
  17:	29 ca                	sub    %ecx,%edx
  19:	29 fc                	sub    %edi,%esp
  1b:	29 cd                	sub    %ecx,%ebp

000000000000001d <r8>:
  1d:	48 29 f8             	sub    %rdi,%rax
  20:	49 29 f8             	sub    %rdi,%r8
  23:	4c 29 cf             	sub    %r9,%rdi
  26:	48 29 fc             	sub    %rdi,%rsp
  29:	48 29 fd             	sub    %rdi,%rbp

000000000000002c <mem>:
  2c:	48 29 3c 24          	sub    %rdi,(%rsp)
  30:	48 29 7d 00          	sub    %rdi,0x0(%rbp)
  34:	48 29 4c 24 64       	sub    %rcx,0x64(%rsp)
  39:	48 29 8c 24 82 00 00 	sub    %rcx,0x82(%rsp)
  40:	00 
  41:	48 29 8c 24 7e ff ff 	sub    %rcx,-0x82(%rsp)
  48:	ff 
  49:	48 29 4d 64          	sub    %rcx,0x64(%rbp)
  4d:	48 29 07             	sub    %rax,(%rdi)

0000000000000050 <bigi>:
  50:	48 83 e8 64          	sub    $0x64,%rax
  54:	48 2d c0 00 00 00    	sub    $0xc0,%rax
  5a:	2d c0 00 00 00       	sub    $0xc0,%eax
  5f:	48 81 e9 c0 00 00 00 	sub    $0xc0,%rcx
  66:	48 81 ea c0 00 00 00 	sub    $0xc0,%rdx
