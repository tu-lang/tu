
movq.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r8>:
   0:	48 89 e0             	mov    %rsp,%rax
   3:	48 89 e8             	mov    %rbp,%rax
   6:	48 89 f8             	mov    %rdi,%rax
   9:	48 89 f0             	mov    %rsi,%rax
   c:	48 89 d0             	mov    %rdx,%rax
   f:	48 89 c8             	mov    %rcx,%rax
  12:	4c 89 c0             	mov    %r8,%rax
  15:	4c 89 c8             	mov    %r9,%rax
  18:	48 89 c0             	mov    %rax,%rax
  1b:	48 89 d8             	mov    %rbx,%rax
  1e:   48 b8 00 00 00 00 84    movabs $0x41a7d78400000000,%rax
  25:   d7 a7 41 
  28:   48 b8 00 00 00 00 84    movabs $0x41a7d78400000000,%rax
  2f:   d7 a7 41 

    
0000000000000000 <float>:
   0:   f3 0f 7e 45 f8          movq   -0x8(%rbp),%xmm0
   5:   f3 44 0f 7e 4d 10       movq   0x10(%rbp),%xmm9
   b:   66 0f d6 45 f8          movq   %xmm0,-0x8(%rbp)
  10:   66 44 0f d6 4d 10       movq   %xmm9,0x10(%rbp)
  16:   66 48 0f 6e c0          movq   %rax,%xmm0
  1b:   66 4d 0f 6e e0          movq   %r8,%xmm12
  20:   66 48 0f 7e c0          movq   %xmm0,%rax
  25:   66 4d 0f 7e e0          movq   %xmm12,%r8