
div_idiv.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <ldiv>:
   0:	f6 f0                	div    %al
   2:	f6 f7                	div    %bh
   4:	f7 f0                	div    %eax
   6:	48 f7 f0             	div    %rax
   9:	f7 f7                	div    %edi
   b:	48 f7 f7             	div    %rdi
   e:	49 f7 f0             	div    %r8
  11:	48 f7 f0             	div    %rax

0000000000000014 <lidiv>:
  14:	f6 f8                	idiv   %al
  16:	f6 ff                	idiv   %bh
  18:	f7 f8                	idiv   %eax
  1a:	48 f7 f8             	idiv   %rax
  1d:	f7 ff                	idiv   %edi
  1f:	48 f7 ff             	idiv   %rdi
  22:	49 f7 f8             	idiv   %r8
  25:	48 f7 f0             	div    %rax

0000000000000000 <lidivq>:
   0:	48 f7 f8             	idiv   %rax
   3:	48 f7 ff             	idiv   %rdi
   6:	49 f7 f8             	idiv   %r8
   9:	49 f7 f9             	idiv   %r9
   c:	48 f7 7c 24 08       	idivq  0x8(%rsp)
  11:	48 f7 7c 24 f0       	idivq  -0x10(%rsp)
  16:	48 f7 7d 08          	idivq  0x8(%rbp)
  1a:	48 f7 7d f0          	idivq  -0x10(%rbp)
  1e:	48 f7 f0             	div    %rax
  21:	49 f7 f1             	div    %r9
  24:	48 f7 38             	idivq  (%rax)
  27:	48 f7 78 08          	idivq  0x8(%rax)
  2b:	49 f7 39             	idivq  (%r9)
  2e:	49 f7 79 f0          	idivq  -0x10(%r9)
