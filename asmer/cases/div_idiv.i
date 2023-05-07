
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
