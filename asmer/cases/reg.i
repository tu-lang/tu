
reg.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <rr>:
   0:	49 89 d4             	mov    %rdx,%r12
   3:	49 89 cd             	mov    %rcx,%r13
   6:	4d 89 c6             	mov    %r8,%r14
   9:	48 89 f4             	mov    %rsi,%rsp
   c:	4c 89 e7             	mov    %r12,%rdi
   f:	4c 89 ef             	mov    %r13,%rdi
  12:	4c 89 f1             	mov    %r14,%rcx
  15:	4c 89 fa             	mov    %r15,%rdx

0000000000000018 <imr>:
  18:	48 c7 c2 00 00 00 00 	mov    $0x0,%rdx
  1f:	49 c7 c2 00 00 00 00 	mov    $0x0,%r10
  26:	49 c7 c6 64 00 00 00 	mov    $0x64,%r14
  2d:	49 c7 c0 00 00 00 00 	mov    $0x0,%r8
  34:	48 c7 c0 38 00 00 00 	mov    $0x38,%rax
  3b:	41 ff d5             	callq  *%r13