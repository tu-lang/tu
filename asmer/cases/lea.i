
lea.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <mem>:
   0:	48 8d 35 10 00 00 00 	lea    0x10(%rip),%rsi        # 17 <test>
   7:	48 8d 35 00 00 00 00 	lea    0x0(%rip),%rsi        # e <mem+0xe>
   e:	48 8d 74 24 10       	lea    0x10(%rsp),%rsi
  13:	48 8d 45 20          	lea    0x20(%rbp),%rax

0000000000000017 <test>:
  17:	48 8d 40 10          	lea    0x10(%rax),%rax
  1b:	4c 8d 48 f0          	lea    -0x10(%rax),%r9
  1f:	49 8d 51 10          	lea    0x10(%r9),%rdx
  23:	4d 8d 41 f0          	lea    -0x10(%r9),%r8
  27:	4d 8d 81 82 00 00 00 	lea    0x82(%r9),%r8
  2e:	4d 8d 81 74 ff ff ff 	lea    -0x8c(%r9),%r8

0000000000000035 <test1>:
  35:	48 8d 15 c4 ff ff ff 	lea    -0x3c(%rip),%rdx        # 0 <mem>
  3c:	48 8d 15 d4 ff ff ff 	lea    -0x2c(%rip),%rdx        # 17 <test>
