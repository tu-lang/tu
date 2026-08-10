
rel.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <func>:
   0:	48 8d 05 00 00 00 00 	lea    0x0(%rip),%rax        # 7 <func+0x7>
   7:	48 8b 05 00 00 00 00 	mov    0x0(%rip),%rax        # e <func+0xe>
   e:	48 89 05 00 00 00 00 	mov    %rax,0x0(%rip)        # 15 <func+0x15>
  15:	48 89 0d 00 00 00 00 	mov    %rcx,0x0(%rip)        # 1c <func+0x1c>
  1c:	4c 8b 05 00 00 00 00 	mov    0x0(%rip),%r8         # 23 <func+0x23>
  23:	4c 89 05 00 00 00 00 	mov    %r8,0x0(%rip)         # 2a <func+0x2a>
