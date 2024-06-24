
push_pop.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <pushri>:
   0:	6a 64                	pushq  $0x64
   2:	68 90 00 00 00       	pushq  $0x90
   7:	68 01 01 00 00       	pushq  $0x101
   c:	68 aa aa aa 00       	pushq  $0xaaaaaa

0000000000000011 <pushr8>:
  11:	50                   	push   %rax
  12:	57                   	push   %rdi
  13:	41 51                	push   %r9
  15:	55                   	push   %rbp
  16:	54                   	push   %rsp

0000000000000000 <pushm>:
   0:	ff 34 24             	pushq  (%rsp)
   3:	ff 74 24 10          	pushq  0x10(%rsp)
   7:	ff 30                	pushq  (%rax)
   9:	ff 70 10             	pushq  0x10(%rax)
   c:	ff 37                	pushq  (%rdi)
   e:	ff 77 10             	pushq  0x10(%rdi)
  11:	41 ff 31             	pushq  (%r9)
  14:	41 ff 71 10          	pushq  0x10(%r9)

0000000000000017 <popr8>:
  17:	58                   	pop    %rax
  18:	5f                   	pop    %rdi
  19:	5d                   	pop    %rbp
  1a:	41 58                	pop    %r8
  1c:	41 59                	pop    %r9
  1e:	5c                   	pop    %rsp
  1f:	5d                   	pop    %rbp
  20:	8f 00                	popq   (%rax)
  22:	41 8f 01             	popq   (%r9)
  25:	8f 44 24 0a          	popq   0xa(%rsp)
  29:	8f 40 0a             	popq   0xa(%rax)
  2c:	41 8f 41 0a          	popq   0xa(%r9)
  30:	41 8f 81 7e ff ff ff 	popq   -0x82(%r9)
  37:	41 8f 81 82 00 00 00 	popq   0x82(%r9)
