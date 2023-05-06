
main.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <write>:
   0:	48 c7 c0 01 00 00 00 	mov    $0x1,%rax
   7:	0f 05                	syscall 
   9:	c3                   	retq   

000000000000000a <die>:
   a:	48 c7 c7 00 00 00 00 	mov    $0x0,%rdi
  11:	48 c7 c0 3c 00 00 00 	mov    $0x3c,%rax
  18:	0f 05                	syscall 
  1a:	c3                   	retq   

000000000000001b <main_main>:
  1b:	55                   	push   %rbp
  1c:	48 89 e5             	mov    %rsp,%rbp
  1f:	48 c7 c7 01 00 00 00 	mov    $0x1,%rdi
  26:	48 8d 35 00 00 00 00 	lea    0x0(%rip),%rsi        # 2d <main_main+0x12>
  2d:	48 c7 c2 0f 00 00 00 	mov    $0xf,%rdx
  34:	e8 c7 ff ff ff       	callq  39 <main_main+0x1e>
  39:	48 89 ec             	mov    %rbp,%rsp
  3c:	5d                   	pop    %rbp
  3d:	c3                   	retq   
