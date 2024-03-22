Disassembly of section .text:

0000000000000000 <il2f_64>:
   0:   f2 48 0f 2a c0          cvtsi2sd %rax,%xmm0
   5:   f2 48 0f 2a c7          cvtsi2sd %rdi,%xmm0
   a:   f2 4c 0f 2a e8          cvtsi2sd %rax,%xmm13
   f:   f2 4c 0f 2a ef          cvtsi2sd %rdi,%xmm13
  14:   f2 49 0f 2a c1          cvtsi2sd %r9,%xmm0
  19:   f2 4d 0f 2a f2          cvtsi2sd %r10,%xmm14
  1e:   f2 48 0f 2a 64 24 04    cvtsi2sdq 0x4(%rsp),%xmm4
  25:   f2 4c 0f 2a 4c 24 08    cvtsi2sdq 0x8(%rsp),%xmm9
  2c:   f2 4c 0f 2a 4c 24 f0    cvtsi2sdq -0x10(%rsp),%xmm9
  33:   f2 4c 0f 2a 0f          cvtsi2sdq (%rdi),%xmm9
  38:   f2 4d 0f 2a 09          cvtsi2sdq (%r9),%xmm9