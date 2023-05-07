
mov_bwlq.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <rr>:
   0:	c6 00 3a             	movb   $0x3a,(%rax)
   3:	66 c7 00 3a 00       	movw   $0x3a,(%rax)
   8:	66 c7 00 80 00       	movw   $0x80,(%rax)
   d:	c7 00 3a 00 00 00    	movl   $0x3a,(%rax)
  13:	48 c7 00 3a 00 00 00 	movq   $0x3a,(%rax)

000000000000001a <b1>:
  1a:	c6 00 3a             	movb   $0x3a,(%rax)
  1d:	c6 07 3a             	movb   $0x3a,(%rdi)
  20:	c6 40 3f 3a          	movb   $0x3a,0x3f(%rax)
  24:	c6 47 3f 3a          	movb   $0x3a,0x3f(%rdi)
  28:	c6 40 3f 7f          	movb   $0x7f,0x3f(%rax)
  2c:	c6 40 3f 80          	movb   $0x80,0x3f(%rax)
  30:	c6 40 44 80          	movb   $0x80,0x44(%rax)
  34:	c6 40 3f 81          	movb   $0x81,0x3f(%rax)
  38:	c6 40 7f 81          	movb   $0x81,0x7f(%rax)
  3c:	c6 80 80 00 00 00 81 	movb   $0x81,0x80(%rax)
  43:	c6 87 80 00 00 00 81 	movb   $0x81,0x80(%rdi)

000000000000004a <w1>:
  4a:	66 c7 00 3a 00       	movw   $0x3a,(%rax)
  4f:	66 c7 07 3a 00       	movw   $0x3a,(%rdi)
  54:	66 c7 40 3f 3a 00    	movw   $0x3a,0x3f(%rax)
  5a:	66 c7 47 3f 3a 00    	movw   $0x3a,0x3f(%rdi)
  60:	66 c7 40 3f 7f 00    	movw   $0x7f,0x3f(%rax)
  66:	66 c7 40 3f 80 00    	movw   $0x80,0x3f(%rax)
  6c:	66 c7 40 44 80 00    	movw   $0x80,0x44(%rax)
  72:	66 c7 40 3f 81 00    	movw   $0x81,0x3f(%rax)
  78:	66 c7 40 7f 81 00    	movw   $0x81,0x7f(%rax)
  7e:	66 c7 80 80 00 00 00 	movw   $0x81,0x80(%rax)
  85:	81 00 
  87:	66 c7 87 80 00 00 00 	movw   $0x81,0x80(%rdi)
  8e:	81 00 

0000000000000090 <l1>:
  90:	c7 00 3a 00 00 00    	movl   $0x3a,(%rax)
  96:	c7 07 3a 00 00 00    	movl   $0x3a,(%rdi)
  9c:	c7 40 3f 3a 00 00 00 	movl   $0x3a,0x3f(%rax)
  a3:	c7 47 3f 3a 00 00 00 	movl   $0x3a,0x3f(%rdi)
  aa:	c7 40 3f 7f 00 00 00 	movl   $0x7f,0x3f(%rax)
  b1:	c7 40 3f 80 00 00 00 	movl   $0x80,0x3f(%rax)
  b8:	c7 40 44 80 00 00 00 	movl   $0x80,0x44(%rax)
  bf:	c7 40 3f 81 00 00 00 	movl   $0x81,0x3f(%rax)
  c6:	c7 40 7f 81 00 00 00 	movl   $0x81,0x7f(%rax)
  cd:	c7 80 80 00 00 00 81 	movl   $0x81,0x80(%rax)
  d4:	00 00 00 
  d7:	c7 87 80 00 00 00 81 	movl   $0x81,0x80(%rdi)
  de:	00 00 00 

00000000000000e1 <q1>:
  e1:	48 c7 00 3a 00 00 00 	movq   $0x3a,(%rax)
  e8:	48 c7 07 3a 00 00 00 	movq   $0x3a,(%rdi)
  ef:	48 c7 40 3f 3a 00 00 	movq   $0x3a,0x3f(%rax)
  f6:	00 
  f7:	48 c7 47 3f 3a 00 00 	movq   $0x3a,0x3f(%rdi)
  fe:	00 
  ff:	48 c7 40 3f 7f 00 00 	movq   $0x7f,0x3f(%rax)
 106:	00 
 107:	48 c7 40 3f 80 00 00 	movq   $0x80,0x3f(%rax)
 10e:	00 
 10f:	48 c7 40 44 80 00 00 	movq   $0x80,0x44(%rax)
 116:	00 
 117:	48 c7 40 3f 81 00 00 	movq   $0x81,0x3f(%rax)
 11e:	00 
 11f:	48 c7 40 7f 81 00 00 	movq   $0x81,0x7f(%rax)
 126:	00 
 127:	48 c7 80 80 00 00 00 	movq   $0x81,0x80(%rax)
 12e:	81 00 00 00 
 132:	48 c7 87 80 00 00 00 	movq   $0x81,0x80(%rdi)
 139:	81 00 00 00 
