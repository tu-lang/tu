
add.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <imr>:
   0:	48 83 c4 00          	add    $0x0,%rsp
   4:	48 83 c5 64          	add    $0x64,%rbp
   8:	48 83 c7 64          	add    $0x64,%rdi
   c:	83 c7 64             	add    $0x64,%edi
   f:	49 83 c1 64          	add    $0x64,%r9

0000000000000013 <r4>:
  13:	01 f8                	add    %edi,%eax
  15:	01 de                	add    %ebx,%esi
  17:	01 ca                	add    %ecx,%edx
  19:	01 fc                	add    %edi,%esp
  1b:	01 cd                	add    %ecx,%ebp

000000000000001d <r8>:
  1d:	48 01 f8             	add    %rdi,%rax
  20:	49 01 f8             	add    %rdi,%r8
  23:	4c 01 cf             	add    %r9,%rdi
  26:	48 01 fc             	add    %rdi,%rsp
  29:	48 01 fd             	add    %rdi,%rbp

000000000000002c <mem>:
  2c:	48 01 3c 24          	add    %rdi,(%rsp)
  30:	48 01 7d 00          	add    %rdi,0x0(%rbp)
  34:	48 01 4c 24 64       	add    %rcx,0x64(%rsp)
  39:	48 01 4d 64          	add    %rcx,0x64(%rbp)
  3d:	48 01 8d 82 00 00 00 	add    %rcx,0x82(%rbp)
  44:	48 01 8d 7e ff ff ff 	add    %rcx,-0x82(%rbp)
  4b:	48 01 07             	add    %rax,(%rdi)

000000000000004e <bigi>:
  4e:	48 83 c0 64          	add    $0x64,%rax
  52:	48 05 c0 00 00 00    	add    $0xc0,%rax
  58:	05 c0 00 00 00       	add    $0xc0,%eax
  5d:	48 81 c1 c0 00 00 00 	add    $0xc0,%rcx
  64:	48 81 c2 c0 00 00 00 	add    $0xc0,%rdx

000000000000006b <trbp>:
  6b:	83 45 00 00          	addl   $0x0,0x0(%rbp)
  6f:	83 45 00 04          	addl   $0x4,0x0(%rbp)
  73:	83 45 0a 04          	addl   $0x4,0xa(%rbp)
  77:	83 45 00 48          	addl   $0x48,0x0(%rbp)
  7b:	83 45 00 80          	addl   $0xffffff80,0x0(%rbp)
  7f:	48 81 45 00 80 00 00 	addq   $0x80,0x0(%rbp)
  86:	00 
  87:	48 81 45 00 aa aa aa 	addq   $0xaaaaaa,0x0(%rbp)
  8e:	00 
  8f:	48 81 45 0a aa aa aa 	addq   $0xaaaaaa,0xa(%rbp)
  96:	00 

0000000000000097 <trsp>:
  97:	83 04 24 00          	addl   $0x0,(%rsp)
  9b:	83 04 24 04          	addl   $0x4,(%rsp)
  9f:	83 44 24 0a 04       	addl   $0x4,0xa(%rsp)
  a4:	83 04 24 48          	addl   $0x48,(%rsp)
  a8:	83 04 24 80          	addl   $0xffffff80,(%rsp)
  ac:	48 81 04 24 80 00 00 	addq   $0x80,(%rsp)
  b3:	00 
  b4:	48 81 44 24 0a 80 00 	addq   $0x80,0xa(%rsp)
  bb:	00 00 
  bd:	48 81 04 24 aa aa aa 	addq   $0xaaaaaa,(%rsp)
  c4:	00 
  c5:	48 81 84 24 82 00 00 	addq   $0xaaaaaa,0x82(%rsp)
  cc:	00 aa aa aa 00 
  d1:	48 81 84 24 7e ff ff 	addq   $0xaaaaaa,-0x82(%rsp)
  d8:	ff aa aa aa 00 
