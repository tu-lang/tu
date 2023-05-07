
imul.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main1>:
   0:	48 6b c0 08          	imul   $0x8,%rax,%rax
   4:	4d 6b c9 08          	imul   $0x8,%r9,%r9
   8:	6b c0 08             	imul   $0x8,%eax,%eax

000000000000000b <main2>:
   b:	48 0f af c7          	imul   %rdi,%rax
   f:	4c 0f af c7          	imul   %rdi,%r8
  13:	49 0f af c0          	imul   %r8,%rax
  17:	4c 89 c0             	mov    %r8,%rax
  1a:	0f af c7             	imul   %edi,%eax

000000000000001d <bigi>:
  1d:	48 6b c0 64          	imul   $0x64,%rax,%rax
  21:	48 69 c0 c0 00 00 00 	imul   $0xc0,%rax,%rax
  28:	69 c0 c0 00 00 00    	imul   $0xc0,%eax,%eax
  2e:	48 69 c9 c0 00 00 00 	imul   $0xc0,%rcx,%rcx
  35:	48 69 d2 c0 00 00 00 	imul   $0xc0,%rdx,%rdx
