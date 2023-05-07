
movzx.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	48 0f b6 c0          	movzbq %al,%rax
   4:	0f b6 c0             	movzbl %al,%eax
   7:	4c 0f b6 c0          	movzbq %al,%r8
   b:	48 0f b6 c3          	movzbq %bl,%rax
   f:	0f b6 c3             	movzbl %bl,%eax
  12:	4c 0f b6 c3          	movzbq %bl,%r8
  16:	48 0f b6 05 26 00 00 	movzbq 0x26(%rip),%rax        # 44 <lable>
  1d:	00 
  1e:	0f b6 05 1f 00 00 00 	movzbl 0x1f(%rip),%eax        # 44 <lable>
  25:	4c 0f b6 05 17 00 00 	movzbq 0x17(%rip),%r8        # 44 <lable>
  2c:	00 
  2d:	48 0f b6 05 00 00 00 	movzbq 0x0(%rip),%rax        # 35 <main+0x35>
  34:	00 
  35:	0f b6 05 00 00 00 00 	movzbl 0x0(%rip),%eax        # 3c <main+0x3c>
  3c:	4c 0f b6 05 00 00 00 	movzbq 0x0(%rip),%r8        # 44 <lable>
  43:	00 

0000000000000044 <lable>:
  44:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
