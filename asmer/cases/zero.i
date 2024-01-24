
zero.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:	f0 c3                	lock retq 
   2:	c3                   	retq   
   3:	c9                   	leaveq 
   4:	c9                   	leaveq 
   5:	0f 05                	syscall 
   6: 0f 01 f9                rdtscp
   7: f3 90                   pause
