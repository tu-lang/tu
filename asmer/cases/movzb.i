
movzb.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	48 0f b6 c0          	movzbq %al,%rax
   4:	0f b6 c0             	movzbl %al,%eax
   7:	4c 0f b6 c0          	movzbq %al,%r8
   b:	4c 0f b6 08          	movzbq (%rax),%r9
   f:	4d 0f b6 08          	movzbq (%r8),%r9
  13:	49 0f b6 00          	movzbq (%r8),%rax
  17:	49 0f b6 40 0a       	movzbq 0xa(%r8),%rax
  1c:	49 0f b6 80 8c 00 00 	movzbq 0x8c(%r8),%rax
  23:	00 
  24:	48 0f b6 c3          	movzbq %bl,%rax
  28:	0f b6 c3             	movzbl %bl,%eax
  2b:	4c 0f b6 c3          	movzbq %bl,%r8
  2f:	48 0f b6 05 26 00 00 	movzbq 0x26(%rip),%rax        # 5d <lable>
  36:	00 
  37:	0f b6 05 1f 00 00 00 	movzbl 0x1f(%rip),%eax        # 5d <lable>
  3e:	4c 0f b6 05 17 00 00 	movzbq 0x17(%rip),%r8        # 5d <lable>
  45:	00 
  46:	48 0f b6 05 00 00 00 	movzbq 0x0(%rip),%rax        # 4e <main+0x4e>
  4d:	00 
  4e:	0f b6 05 00 00 00 00 	movzbl 0x0(%rip),%eax        # 55 <main+0x55>
  55:	4c 0f b6 05 00 00 00 	movzbq 0x0(%rip),%r8        # 5d <lable>
  5c:	00 

000000000000005d <lable>:
  5d:	4c 0f b6 05 00 00 00 	movzbq 0x0(%rip),%r8        # 65 <lable+0x8>
  64:	00 
