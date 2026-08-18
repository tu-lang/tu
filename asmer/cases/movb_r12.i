
movb_r12.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <main>:
   0:   41 c6 00 00             movb   $0x0,(%r8)
   4:   41 c6 04 24 00          movb   $0x0,(%r12)
   9:   41 c6 44 24 01 00       movb   $0x0,0x1(%r12)
   f:   41 c6 45 00 00          movb   $0x0,0x0(%r13)
  14:   41 c6 45 01 00          movb   $0x0,0x1(%r13)
  19:   41 c7 04 24 00 00 00    movl   $0x0,(%r12)
  20:   00 
  21:   41 c7 44 24 01 00 00    movl   $0x0,0x1(%r12)
  28:   00 00 
  2a:   41 88 04 24             movb   %al,(%r12)
  2e:   41 8a 04 24             movb   (%r12),%al
  32:   41 89 04 24             movl   %eax,(%r12)
  36:   41 8b 04 24             movl   (%r12),%eax
  3a:   66 41 c7 44 24 01 00    movw   $0x0,0x1(%r12)
  41:   00 
  42:   c3                      ret
