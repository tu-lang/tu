
cmpxchgl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r4>:
   0:	0f b1 11             	cmpxchg %edx,(%rcx)
   3:	41 0f b1 11          	cmpxchg %edx,(%r9)
   7:	0f b1 c1             	cmpxchg %eax,%ecx
   a:	0f b1 c8             	cmpxchg %ecx,%eax
0000000000000000 <rmr1>:
   0:   f0 0f b0 1a             lock cmpxchg %bl,(%rdx)
   4:   f0 0f b0 02             lock cmpxchg %al,(%rdx)
   8:   f0 0f b0 0a             lock cmpxchg %cl,(%rdx)