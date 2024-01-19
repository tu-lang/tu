
cmp.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <imm>:
   0:	48 83 f8 01          	cmp    $0x1,%rax
   4:	83 f8 00             	cmp    $0x0,%eax

0000000000000007 <rr>:
   7:	48 39 f8             	cmp    %rdi,%rax
   a:	39 f8                	cmp    %edi,%eax
   c:	48 39 f7             	cmp    %rsi,%rdi

000000000000000f <common>:
   f:   48 3d 7f ff ff ff       cmp    $0xffffffffffffff7f,%rax
  15:   3d 7f ff ff ff          cmp    $0xffffff7f,%eax
  1a:   48 81 f9 7f ff ff ff    cmp    $0xffffffffffffff7f,%rcx
  21:   81 f9 7f ff ff ff       cmp    $0xffffff7f,%ecx
  27:   48 83 f8 7f             cmp    $0x7f,%rax
  2b:   83 f8 7f                cmp    $0x7f,%eax
  2e:   48 83 f9 7f             cmp    $0x7f,%rcx
  32:   83 f9 7f                cmp    $0x7f,%ecx
  35:   48 3d 80 00 00 00       cmp    $0x80,%rax
  3b:   3d 80 00 00 00          cmp    $0x80,%eax
  40:   48 81 f9 80 00 00 00    cmp    $0x80,%rcx
  47:   81 f9 80 00 00 00       cmp    $0x80,%ecx
  4d:   48 3d ff 00 00 00       cmp    $0xff,%rax
  53:   3d ff 00 00 00          cmp    $0xff,%eax
  58:   48 81 f9 ff 00 00 00    cmp    $0xff,%rcx
  5f:   81 f9 ff 00 00 00       cmp    $0xff,%ecx
  65:   83 f8 ff                cmp    $0xffffffff,%eax
  68:   83 f9 ff                cmp    $0xffffffff,%ecx
  6b:   48 3d 01 f0 ff ff       cmp    $0xfffffffffffff001,%rax
  71:   3d 01 f0 ff ff          cmp    $0xfffff001,%eax
  76:   48 81 f9 01 f0 ff ff    cmp    $0xfffffffffffff001,%rcx
  7d:   81 f9 01 f0 ff ff       cmp    $0xfffff001,%ecx