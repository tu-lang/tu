
cmp.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <imm>:
   0:	48 83 f8 01          	cmp    $0x1,%rax
   4:	83 f8 00             	cmp    $0x0,%eax

0000000000000007 <rr>:
   7:	48 39 f8             	cmp    %rdi,%rax
   a:	39 f8                	cmp    %edi,%eax
   c:	48 39 f7             	cmp    %rsi,%rdi
