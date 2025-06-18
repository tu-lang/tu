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
   0:   f2 0f 2a c0             cvtsi2sd %eax,%xmm0
   4:   f2 0f 2a c7             cvtsi2sd %edi,%xmm0
   8:   f2 44 0f 2a e8          cvtsi2sd %eax,%xmm13
   d:   f2 44 0f 2a ef          cvtsi2sd %edi,%xmm13
  12:   f2 0f 2a 64 24 04       cvtsi2sdl 0x4(%rsp),%xmm4
  18:   f2 44 0f 2a 4c 24 08    cvtsi2sdl 0x8(%rsp),%xmm9
  1f:   f2 44 0f 2a 4c 24 f0    cvtsi2sdl -0x10(%rsp),%xmm9
   0:   f3 0f 2a c0             cvtsi2ss %eax,%xmm0
   4:   f3 0f 2a c7             cvtsi2ss %edi,%xmm0
   8:   f3 44 0f 2a e8          cvtsi2ss %eax,%xmm13
   d:   f3 44 0f 2a ef          cvtsi2ss %edi,%xmm13
  12:   f3 0f 2a 64 24 04       cvtsi2ssl 0x4(%rsp),%xmm4
  18:   f3 44 0f 2a 4c 24 08    cvtsi2ssl 0x8(%rsp),%xmm9
  1f:   f3 44 0f 2a 4c 24 f0    cvtsi2ssl -0x10(%rsp),%xmm9

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

0000000000000000 <xorpsinst>:
   0:   0f 57 c9                xorps  %xmm1,%xmm1
   3:   44 0f 57 c9             xorps  %xmm1,%xmm9
   7:   41 0f 57 d1             xorps  %xmm9,%xmm2
   b:   45 0f 57 ca             xorps  %xmm10,%xmm9
   f:   0f 57 4d 04             xorps  0x4(%rbp),%xmm1
  13:   44 0f 57 4d 04          xorps  0x4(%rbp),%xmm9
  18:   0f 57 4c 24 04          xorps  0x4(%rsp),%xmm1
  1d:   44 0f 57 4c 24 04       xorps  0x4(%rsp),%xmm9

0000000000000023 <xorpdinst>:
  23:   66 0f 57 c9             xorpd  %xmm1,%xmm1
  27:   66 44 0f 57 c9          xorpd  %xmm1,%xmm9
  2c:   66 41 0f 57 d1          xorpd  %xmm9,%xmm2
  31:   66 45 0f 57 ca          xorpd  %xmm10,%xmm9
  36:   66 0f 57 4d 04          xorpd  0x4(%rbp),%xmm1
  3b:   66 44 0f 57 4d 04       xorpd  0x4(%rbp),%xmm9
  41:   66 0f 57 4c 24 04       xorpd  0x4(%rsp),%xmm1
  47:   66 44 0f 57 4c 24 04    xorpd  0x4(%rsp),%xmm9

0000000000000000 <cvtps2pdinst>:
   0:   0f 5a c8                cvtps2pd %xmm0,%xmm1
   3:   f3 0f 5a c8             cvtss2sd %xmm0,%xmm1
   7:   44 0f 5a c8             cvtps2pd %xmm0,%xmm9
   b:   f3 44 0f 5a c8          cvtss2sd %xmm0,%xmm9
  10:   41 0f 5a d1             cvtps2pd %xmm9,%xmm2
  14:   f3 41 0f 5a d1          cvtss2sd %xmm9,%xmm2
  19:   45 0f 5a e1             cvtps2pd %xmm9,%xmm12
  1d:   f3 45 0f 5a e1          cvtss2sd %xmm9,%xmm12
  22:   0f 5a 45 08             cvtps2pd 0x8(%rbp),%xmm0
  26:   f3 0f 5a 45 08          cvtss2sd 0x8(%rbp),%xmm0
  2b:   44 0f 5a 4d f0          cvtps2pd -0x10(%rbp),%xmm9
  30:   f3 44 0f 5a 4d f0       cvtss2sd -0x10(%rbp),%xmm9
  36:   0f 5a 07                cvtps2pd (%rdi),%xmm0
  39:   f3 0f 5a 07             cvtss2sd (%rdi),%xmm0
  3d:   44 0f 5a 0f             cvtps2pd (%rdi),%xmm9
  41:   f3 44 0f 5a 0f          cvtss2sd (%rdi),%xmm9
  46:   45 0f 5a 09             cvtps2pd (%r9),%xmm9
  4a:   f3 45 0f 5a 09          cvtss2sd (%r9),%xmm9

000000000000004f <cvtpd2psinst>:
  4f:   66 0f 5a c8             cvtpd2ps %xmm0,%xmm1
  53:   f2 0f 5a c8             cvtsd2ss %xmm0,%xmm1
  57:   66 44 0f 5a c8          cvtpd2ps %xmm0,%xmm9
  5c:   f2 44 0f 5a c8          cvtsd2ss %xmm0,%xmm9
  61:   66 41 0f 5a d1          cvtpd2ps %xmm9,%xmm2
  66:   f2 41 0f 5a d1          cvtsd2ss %xmm9,%xmm2
  6b:   66 45 0f 5a e1          cvtpd2ps %xmm9,%xmm12
  70:   f2 45 0f 5a e1          cvtsd2ss %xmm9,%xmm12
  75:   66 0f 5a 45 08          cvtpd2ps 0x8(%rbp),%xmm0
  7a:   f2 0f 5a 45 08          cvtsd2ss 0x8(%rbp),%xmm0
  7f:   66 44 0f 5a 4d f0       cvtpd2ps -0x10(%rbp),%xmm9
  85:   f2 44 0f 5a 4d f0       cvtsd2ss -0x10(%rbp),%xmm9
  8b:   66 0f 5a 07             cvtpd2ps (%rdi),%xmm0
  8f:   f2 0f 5a 07             cvtsd2ss (%rdi),%xmm0
  93:   66 44 0f 5a 0f          cvtpd2ps (%rdi),%xmm9
  98:   f2 44 0f 5a 0f          cvtsd2ss (%rdi),%xmm9
  9d:   66 45 0f 5a 09          cvtpd2ps (%r9),%xmm9
  a2:   f2 45 0f 5a 09          cvtsd2ss (%r9),%xmm9

0000000000000000 <cvttss2siqinst>:
   0:	f3 0f 2c c0          	cvttss2si %xmm0,%eax
   4:	f3 41 0f 2c c1       	cvttss2si %xmm9,%eax
   9:	f3 0f 2c d0          	cvttss2si %xmm0,%edx
   d:	f3 41 0f 2c d1       	cvttss2si %xmm9,%edx
  
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
   0:	f2 0f 2c c0          	cvttsd2si %xmm0,%eax
   4:	f2 41 0f 2c d1       	cvttsd2si %xmm9,%edx
   9:	f2 48 0f 2c c0       	cvttsd2si %xmm0,%rax
   e:	f2 4c 0f 2c d0       	cvttsd2si %xmm0,%r10
  13:	f2 49 0f 2c c2       	cvttsd2si %xmm10,%rax
  18:	f2 4d 0f 2c e3       	cvttsd2si %xmm11,%r12


0000000000000000 <addop>:
   0:	f2 0f 58 85 2c 01 00 	addsd  0x12c(%rbp),%xmm0
   7:	00 
   8:	f2 44 0f 58 8d 0c fe 	addsd  -0x1f4(%rbp),%xmm9
   f:	ff ff 
  11:	f2 0f 58 c1          	addsd  %xmm1,%xmm0
  15:	f2 44 0f 58 c9       	addsd  %xmm1,%xmm9
  1a:	f2 41 0f 58 d1       	addsd  %xmm9,%xmm2
  1f:	f2 45 0f 58 d1       	addsd  %xmm9,%xmm10
  24:	f3 0f 58 85 2c 01 00 	addss  0x12c(%rbp),%xmm0
  2b:	00 
  2c:	f3 44 0f 58 8d 0c fe 	addss  -0x1f4(%rbp),%xmm9
  33:	ff ff 
  35:	f3 0f 58 c1          	addss  %xmm1,%xmm0
  39:	f3 44 0f 58 c9       	addss  %xmm1,%xmm9
  3e:	f3 41 0f 58 d1       	addss  %xmm9,%xmm2
  43:	f3 45 0f 58 d1       	addss  %xmm9,%xmm10

0000000000000048 <subop>:
  48:	f2 0f 5c 85 2c 01 00 	subsd  0x12c(%rbp),%xmm0
  4f:	00 
  50:	f2 44 0f 5c 8d 0c fe 	subsd  -0x1f4(%rbp),%xmm9
  57:	ff ff 
  59:	f2 0f 5c c1          	subsd  %xmm1,%xmm0
  5d:	f2 44 0f 5c c9       	subsd  %xmm1,%xmm9
  62:	f2 41 0f 5c d1       	subsd  %xmm9,%xmm2
  67:	f2 45 0f 5c d1       	subsd  %xmm9,%xmm10
  6c:	f3 0f 5c 85 2c 01 00 	subss  0x12c(%rbp),%xmm0
  73:	00 
  74:	f3 44 0f 5c 8d 0c fe 	subss  -0x1f4(%rbp),%xmm9
  7b:	ff ff 
  7d:	f3 0f 5c c1          	subss  %xmm1,%xmm0
  81:	f3 44 0f 5c c9       	subss  %xmm1,%xmm9
  86:	f3 41 0f 5c d1       	subss  %xmm9,%xmm2
  8b:	f3 45 0f 5c d1       	subss  %xmm9,%xmm10

0000000000000090 <mulop>:
  90:	f2 0f 59 85 2c 01 00 	mulsd  0x12c(%rbp),%xmm0
  97:	00 
  98:	f2 44 0f 59 8d 0c fe 	mulsd  -0x1f4(%rbp),%xmm9
  9f:	ff ff 
  a1:	f2 0f 59 c1          	mulsd  %xmm1,%xmm0
  a5:	f2 44 0f 59 c9       	mulsd  %xmm1,%xmm9
  aa:	f2 41 0f 59 d1       	mulsd  %xmm9,%xmm2
  af:	f2 45 0f 59 d1       	mulsd  %xmm9,%xmm10
  b4:	f3 0f 59 85 2c 01 00 	mulss  0x12c(%rbp),%xmm0
  bb:	00 
  bc:	f3 44 0f 59 8d 0c fe 	mulss  -0x1f4(%rbp),%xmm9
  c3:	ff ff 
  c5:	f3 0f 59 c1          	mulss  %xmm1,%xmm0
  c9:	f3 44 0f 59 c9       	mulss  %xmm1,%xmm9
  ce:	f3 41 0f 59 d1       	mulss  %xmm9,%xmm2
  d3:	f3 45 0f 59 d1       	mulss  %xmm9,%xmm10

00000000000000d8 <divop>:
  d8:	f2 0f 5e 85 2c 01 00 	divsd  0x12c(%rbp),%xmm0
  df:	00 
  e0:	f2 44 0f 5e 8d 0c fe 	divsd  -0x1f4(%rbp),%xmm9
  e7:	ff ff 
  e9:	f2 0f 5e c1          	divsd  %xmm1,%xmm0
  ed:	f2 44 0f 5e c9       	divsd  %xmm1,%xmm9
  f2:	f2 41 0f 5e d1       	divsd  %xmm9,%xmm2
  f7:	f2 45 0f 5e d1       	divsd  %xmm9,%xmm10
  fc:	f3 0f 5e 85 2c 01 00 	divss  0x12c(%rbp),%xmm0
 103:	00 
 104:	f3 44 0f 5e 8d 0c fe 	divss  -0x1f4(%rbp),%xmm9
 10b:	ff ff 
 10d:	f3 0f 5e c1          	divss  %xmm1,%xmm0
 111:	f3 44 0f 5e c9       	divss  %xmm1,%xmm9
 116:	f3 41 0f 5e d1       	divss  %xmm9,%xmm2
 11b:	f3 45 0f 5e d1       	divss  %xmm9,%xmm10

0000000000000120 <movop>:
 120:	f2 0f 10 85 2c 01 00 	movsd  0x12c(%rbp),%xmm0
 127:	00 
 128:	f2 44 0f 10 8d 0c fe 	movsd  -0x1f4(%rbp),%xmm9
 12f:	ff ff 
 131:	f2 0f 10 c1          	movsd  %xmm1,%xmm0
 135:	f2 44 0f 10 c9       	movsd  %xmm1,%xmm9
 13a:	f2 41 0f 10 d1       	movsd  %xmm9,%xmm2
 13f:	f2 45 0f 10 d1       	movsd  %xmm9,%xmm10
 144:	f3 0f 10 85 2c 01 00 	movss  0x12c(%rbp),%xmm0
 14b:	00 
 14c:	f3 44 0f 10 8d 0c fe 	movss  -0x1f4(%rbp),%xmm9
 153:	ff ff 
 155:	f3 0f 10 c1          	movss  %xmm1,%xmm0
 159:	f3 44 0f 10 c9       	movss  %xmm1,%xmm9
 15e:	f3 41 0f 10 d1       	movss  %xmm9,%xmm2
 163:	f3 45 0f 10 d1       	movss  %xmm9,%xmm10

0000000000000000 <ucomisdinst>:
   0:   66 0f 2e c8             ucomisd %xmm0,%xmm1
   4:   66 44 0f 2e d0          ucomisd %xmm0,%xmm10
   9:   66 41 0f 2e cb          ucomisd %xmm11,%xmm1
   e:   66 45 0f 2e cb          ucomisd %xmm11,%xmm9
  13:   66 0f 2e 4c 24 08       ucomisd 0x8(%rsp),%xmm1
  19:   66 44 0f 2e 4c 24 08    ucomisd 0x8(%rsp),%xmm9
  20:   66 0f 2e 4d 08          ucomisd 0x8(%rbp),%xmm1
  25:   66 44 0f 2e 4d 08       ucomisd 0x8(%rbp),%xmm9

0000000000000000 <ucomissinst>:
   0:   0f 2e c8                ucomiss %xmm0,%xmm1
   3:   44 0f 2e d0             ucomiss %xmm0,%xmm10
   7:   41 0f 2e cb             ucomiss %xmm11,%xmm1
   b:   45 0f 2e cb             ucomiss %xmm11,%xmm9
   f:   0f 2e 4c 24 08          ucomiss 0x8(%rsp),%xmm1
  14:   44 0f 2e 4c 24 08       ucomiss 0x8(%rsp),%xmm9
  1a:   0f 2e 4d 08             ucomiss 0x8(%rbp),%xmm1
  1e:   44 0f 2e 4d 08          ucomiss 0x8(%rbp),%xmm9

000000000000045e <cvtsi2ssqinst>:
 45e:   f3 48 0f 2a c0          cvtsi2ss %rax,%xmm0
 463:   f3 48 0f 2a c7          cvtsi2ss %rdi,%xmm0
 468:   f3 4c 0f 2a e8          cvtsi2ss %rax,%xmm13
 46d:   f3 4c 0f 2a ef          cvtsi2ss %rdi,%xmm13
 472:   f3 48 0f 2a 64 24 04    cvtsi2ssq 0x4(%rsp),%xmm4
 479:   f3 4c 0f 2a 4c 24 08    cvtsi2ssq 0x8(%rsp),%xmm9
 480:   f3 4c 0f 2a 4c 24 f0    cvtsi2ssq -0x10(%rsp),%xmm9