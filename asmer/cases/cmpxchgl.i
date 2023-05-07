
cmpxchgl.o:     file format elf64-x86-64


Disassembly of section .text:

0000000000000000 <r4>:
   0:	0f b1 11             	cmpxchg %edx,(%rcx)
   3:	41 0f b1 11          	cmpxchg %edx,(%r9)
   7:	0f b1 c1             	cmpxchg %eax,%ecx
   a:	0f b1 c8             	cmpxchg %ecx,%eax
