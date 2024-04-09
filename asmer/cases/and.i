
and.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <imr>:
   0:	48 83 e4 00          	and    $0x0,%rsp
   4:	48 83 e5 64          	and    $0x64,%rbp
   8:	48 83 e7 64          	and    $0x64,%rdi
   c:	83 e7 64             	and    $0x64,%edi
   f:	49 83 e1 64          	and    $0x64,%r9

0000000000000013 <r4>:
  13:	21 f8                	and    %edi,%eax
  15:	21 de                	and    %ebx,%esi
  17:	21 ca                	and    %ecx,%edx
  19:	21 fc                	and    %edi,%esp
  1b:	21 cd                	and    %ecx,%ebp

000000000000001d <r8>:
  1d:	48 21 f8             	and    %rdi,%rax
  20:	49 21 f8             	and    %rdi,%r8
  23:	4c 21 cf             	and    %r9,%rdi
  26:	48 21 fc             	and    %rdi,%rsp
  29:	48 21 fd             	and    %rdi,%rbp

000000000000002c <mem>:
  2c:	48 21 3c 24          	and    %rdi,(%rsp)
  30:	48 21 7d 00          	and    %rdi,0x0(%rbp)
  34:	48 21 4c 24 64       	and    %rcx,0x64(%rsp)
  39:	48 21 4d 64          	and    %rcx,0x64(%rbp)
  3d:	48 21 8d 82 00 00 00 	and    %rcx,0x82(%rbp)
  44:	48 21 8d 7e ff ff ff 	and    %rcx,-0x82(%rbp)
  4b:	48 21 07             	and    %rax,(%rdi)

000000000000004e <bigi>:
  4e:	48 83 e0 64          	and    $0x64,%rax
  52:	48 25 c0 00 00 00    	and    $0xc0,%rax
  58:	25 c0 00 00 00       	and    $0xc0,%eax
  5d:	48 81 e1 c0 00 00 00 	and    $0xc0,%rcx
  64:	48 81 e2 c0 00 00 00 	and    $0xc0,%rdx

000000000000006b <i8i>:
  6b:   48 83 e0 01             and    $0x1,%rax
  6f:   83 e0 01                and    $0x1,%eax
  72:   80 e0 01                and    $0x1,%al
  75:   80 e1 01                and    $0x1,%cl
  78:   80 e2 01                and    $0x1,%dl
  7b:   80 e3 01                and    $0x1,%bl
  7e:   20 d0                   and    %dl,%al
  80:   21 d0                   and    %edx,%eax
  82:   48 21 d0                and    %rdx,%rax