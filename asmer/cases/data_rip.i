
data_rip.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	8b 05 00 00 00 00    	movl   0x0(%rip),%eax
   6:	8b 05 00 00 00 00    	movl   0x0(%rip),%eax
   c:	89 05 00 00 00 00    	movl   %eax,0x0(%rip)
  12:	48 8d 05 00 00 00 00 	lea    0x0(%rip),%rax
  19:	c3                   	ret
