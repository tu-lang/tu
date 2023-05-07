
movzbl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	48 0f b6 c0          	movzbq %al,%rax
   4:	0f b6 c0             	movzbl %al,%eax
   7:	4c 0f b6 c0          	movzbq %al,%r8
   b:	4c 0f b6 08          	movzbq (%rax),%r9
   f:	0f b6 00             	movzbl (%rax),%eax
  12:	4d 0f b6 08          	movzbq (%r8),%r9
  16:	49 0f b6 00          	movzbq (%r8),%rax
  1a:	49 0f b6 40 0a       	movzbq 0xa(%r8),%rax
  1f:	49 0f b6 80 8c 00 00 	movzbq 0x8c(%r8),%rax
  26:	00 
  27:	48 0f b6 c3          	movzbq %bl,%rax
  2b:	0f b6 c3             	movzbl %bl,%eax
  2e:	4c 0f b6 c3          	movzbq %bl,%r8
  32:	48 0f b6 05 26 00 00 	movzbq 0x26(%rip),%rax        # 60 <lable>
  39:	00 
  3a:	0f b6 05 1f 00 00 00 	movzbl 0x1f(%rip),%eax        # 60 <lable>
  41:	4c 0f b6 05 17 00 00 	movzbq 0x17(%rip),%r8        # 60 <lable>
  48:	00 
  49:	48 0f b6 05 00 00 00 	movzbq 0x0(%rip),%rax        # 51 <main+0x51>
  50:	00 
  51:	0f b6 05 00 00 00 00 	movzbl 0x0(%rip),%eax        # 58 <main+0x58>
  58:	4c 0f b6 05 00 00 00 	movzbq 0x0(%rip),%r8        # 60 <lable>
  5f:	00 

0000000000000060 <lable>:
  60:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
