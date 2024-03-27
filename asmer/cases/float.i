Disassembly of section .text:

0000000000000000 <il2f_64>:
   0:   f2 48 0f 2a c0          cvtsi2sd %rax,%xmm0
   5:   f2 48 0f 2a c7          cvtsi2sd %rdi,%xmm0
   a:   f2 4c 0f 2a e8          cvtsi2sd %rax,%xmm13
   f:   f2 4c 0f 2a ef          cvtsi2sd %rdi,%xmm13
  14:   f2 49 0f 2a c1          cvtsi2sd %r9,%xmm0
  19:   f2 4d 0f 2a f2          cvtsi2sd %r10,%xmm14
  1e:   f2 48 0f 2a 64 24 04    cvtsi2sdq 0x4(%rsp),%xmm4
  25:   f2 4c 0f 2a 4c 24 08    cvtsi2sdq 0x8(%rsp),%xmm9
  2c:   f2 4c 0f 2a 4c 24 f0    cvtsi2sdq -0x10(%rsp),%xmm9
  33:   f2 4c 0f 2a 0f          cvtsi2sdq (%rdi),%xmm9
  38:   f2 4d 0f 2a 09          cvtsi2sdq (%r9),%xmm9

0000000000000000 <cvtsi2ssinst>:
   0:	f3 48 0f 2a c0       	cvtsi2ss %rax,%xmm0
   5:	f3 48 0f 2a c7       	cvtsi2ss %rdi,%xmm0
   a:	f3 4c 0f 2a e8       	cvtsi2ss %rax,%xmm13
   f:	f3 4c 0f 2a ef       	cvtsi2ss %rdi,%xmm13
  14:	f3 49 0f 2a c1       	cvtsi2ss %r9,%xmm0
  19:	f3 4d 0f 2a f2       	cvtsi2ss %r10,%xmm14
  1e:	f3 0f 2a 64 24 04    	cvtsi2ssl 0x4(%rsp),%xmm4
  24:	f3 44 0f 2a 4c 24 08 	cvtsi2ssl 0x8(%rsp),%xmm9
  2b:	f3 44 0f 2a 4c 24 f0 	cvtsi2ssl -0x10(%rsp),%xmm9
  32:	f3 44 0f 2a 0f       	cvtsi2ssl (%rdi),%xmm9
  37:	f3 45 0f 2a 09       	cvtsi2ssl (%r9),%xmm9
  3c:	f3 0f 2a c0          	cvtsi2ss %eax,%xmm0
  40:	f3 0f 2a c2          	cvtsi2ss %edx,%xmm0
  44:	f3 44 0f 2a ca       	cvtsi2ss %edx,%xmm9

0000000000000000 <movsd_64>:
   0:   f2 0f 10 45 f8          movsd  -0x8(%rbp),%xmm0
   5:   f2 44 0f 10 4d 10       movsd  0x10(%rbp),%xmm9
   b:   f2 0f 11 45 f8          movsd  %xmm0,-0x8(%rbp)
  10:   f2 44 0f 11 4d 10       movsd  %xmm9,0x10(%rbp)

0000000000000000 <movss_32>:
  16:	f3 0f 10 45 f8       	movss  -0x8(%rbp),%xmm0
  1b:	f3 44 0f 10 4d 10    	movss  0x10(%rbp),%xmm9
  21:	f3 0f 11 45 f8       	movss  %xmm0,-0x8(%rbp)
  26:	f3 44 0f 11 4d 10    	movss  %xmm9,0x10(%rbp)

0000000000000000 <addinst>:
   0:	f2 0f 58 45 f0       	addsd  -0x10(%rbp),%xmm0
   5:	f2 44 0f 58 4d 08    	addsd  0x8(%rbp),%xmm9
   b:	f3 0f 58 45 f8       	addss  -0x8(%rbp),%xmm0
  10:	f3 44 0f 58 4d 10    	addss  0x10(%rbp),%xmm9

0000000000000000 <subinst>:
  49:   f2 0f 5c 45 f0          subsd  -0x10(%rbp),%xmm0
  4e:   f2 44 0f 5c 55 08       subsd  0x8(%rbp),%xmm10
  54:   f3 0f 5c 45 f0          subss  -0x10(%rbp),%xmm0
  59:   f3 44 0f 5c 55 08       subss  0x8(%rbp),%xmm10

0000000000000000 <mulinst>:
   0:	f2 0f 59 45 f0       	mulsd  -0x10(%rbp),%xmm0
   5:	f2 44 0f 59 55 08    	mulsd  0x8(%rbp),%xmm10
   b:	f3 0f 59 45 f0       	mulss  -0x10(%rbp),%xmm0
  10:	f3 44 0f 59 55 08    	mulss  0x8(%rbp),%xmm10

0000000000000000 <div_op>:
   0:	f2 0f 5e 45 f0       	divsd  -0x10(%rbp),%xmm0
   5:	f2 44 0f 5e 55 08    	divsd  0x8(%rbp),%xmm10
   b:	f3 0f 5e 45 f0       	divss  -0x10(%rbp),%xmm0
  10:	f3 44 0f 5e 55 08    	divss  0x8(%rbp),%xmm10

0000000000000000 <unpcklpsinst>:
   0:	0f 14 c0             	unpcklps %xmm0,%xmm0
   3:	44 0f 14 c8          	unpcklps %xmm0,%xmm9
   7:	41 0f 14 c2          	unpcklps %xmm10,%xmm0
   b:	45 0f 14 db          	unpcklps %xmm11,%xmm11
   f:	0f 14 44 24 08       	unpcklps 0x8(%rsp),%xmm0
  14:	44 0f 14 4c 24 08    	unpcklps 0x8(%rsp),%xmm9

0000000000000000 <cvts2pdinst>:
   0:	0f 5a c8             	cvtps2pd %xmm0,%xmm1
   3:	44 0f 5a c8          	cvtps2pd %xmm0,%xmm9
   7:	41 0f 5a d1          	cvtps2pd %xmm9,%xmm2
   b:	45 0f 5a e1          	cvtps2pd %xmm9,%xmm12
   f:	0f 5a 45 08          	cvtps2pd 0x8(%rbp),%xmm0
  13:	44 0f 5a 4d f0       	cvtps2pd -0x10(%rbp),%xmm9
  18:	0f 5a 07             	cvtps2pd (%rdi),%xmm0
  1b:	44 0f 5a 0f          	cvtps2pd (%rdi),%xmm9
  1f:	45 0f 5a 09          	cvtps2pd (%r9),%xmm9

0000000000000000 <cvtpd2psinst>:
   0:	66 0f 5a c8          	cvtpd2ps %xmm0,%xmm1
   4:	66 44 0f 5a c8       	cvtpd2ps %xmm0,%xmm9
   9:	66 41 0f 5a d1       	cvtpd2ps %xmm9,%xmm2
   e:	66 45 0f 5a e1       	cvtpd2ps %xmm9,%xmm12
  13:	66 0f 5a 45 08       	cvtpd2ps 0x8(%rbp),%xmm0
  18:	66 44 0f 5a 4d f0    	cvtpd2ps -0x10(%rbp),%xmm9
  1e:	66 0f 5a 07          	cvtpd2ps (%rdi),%xmm0
  22:	66 44 0f 5a 0f       	cvtpd2ps (%rdi),%xmm9
  27:	66 45 0f 5a 09       	cvtpd2ps (%r9),%xmm9

0000000000000000 <cvttss2siqinst>:
   0:	f3 0f 2c c0          	cvttss2si %xmm0,%eax
   4:	f3 41 0f 2c c1       	cvttss2si %xmm9,%eax
   9:	f3 0f 2c d0          	cvttss2si %xmm0,%edx
   d:	f3 41 0f 2c d1       	cvttss2si %xmm9,%edx
   
  12:	f3 48 0f 2c f8       	cvttss2si %xmm0,%rdi
  17:	f3 4c 0f 2c c8       	cvttss2si %xmm0,%r9
  1c:	f3 49 0f 2c f9       	cvttss2si %xmm9,%rdi
  21:	f3 4d 0f 2c d1       	cvttss2si %xmm9,%r10

0000000000000000 <cvttsd2siinst>:
   0:	f2 0f 2c c0          	cvttsd2si %xmm0,%eax
   4:	f2 41 0f 2c d1       	cvttsd2si %xmm9,%edx
   9:	f2 48 0f 2c c0       	cvttsd2si %xmm0,%rax
   e:	f2 4c 0f 2c d0       	cvttsd2si %xmm0,%r10
  13:	f2 49 0f 2c c2       	cvttsd2si %xmm10,%rax
  18:	f2 4d 0f 2c e3       	cvttsd2si %xmm11,%r12
