
movsbl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	0f be c0             	movsbl %al,%eax
   3:	0f be c3             	movsbl %bl,%eax
   6:	0f be 05 07 00 00 00 	movsbl 0x7(%rip),%eax        # 14 <lable>
   d:	0f be 05 00 00 00 00 	movsbl 0x0(%rip),%eax        # 14 <lable>

0000000000000014 <lable>:
  14:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
