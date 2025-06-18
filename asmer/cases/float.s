il2f_64:
    cvtsi2sdq	%rax, %xmm0
    cvtsi2sdq	%rdi, %xmm0
    cvtsi2sdq	%rax, %xmm13
    cvtsi2sdq	%rdi, %xmm13
    cvtsi2sdq	%r9, %xmm0
    cvtsi2sdq	%r10, %xmm14
    cvtsi2sdq   4(%rsp) , %xmm4
    cvtsi2sdq   8(%rsp) , %xmm9
    cvtsi2sdq   -16(%rsp) , %xmm9
    cvtsi2sdq   (%rdi) , %xmm9
    cvtsi2sdq   (%r9) , %xmm9
    cvtsi2sdl   %eax, %xmm0
    cvtsi2sdl   %edi, %xmm0
    cvtsi2sdl   %eax, %xmm13
    cvtsi2sdl   %edi, %xmm13
    cvtsi2sdl   4(%rsp) , %xmm4
    cvtsi2sdl   8(%rsp) , %xmm9
    cvtsi2sdl   -16(%rsp) , %xmm9
	cvtsi2ssl   %eax, %xmm0
    cvtsi2ssl   %edi, %xmm0
    cvtsi2ssl   %eax, %xmm13
    cvtsi2ssl   %edi, %xmm13
    cvtsi2ssl   4(%rsp) , %xmm4
    cvtsi2ssl   8(%rsp) , %xmm9
    cvtsi2ssl   -16(%rsp) , %xmm9

cvtsi2ssinst:
    cvtsi2ss	%rax, %xmm0
    cvtsi2ss	%rdi, %xmm0
    cvtsi2ss	%rax, %xmm13
    cvtsi2ss	%rdi, %xmm13
    cvtsi2ss	%r9, %xmm0
    cvtsi2ss	%r10, %xmm14
    cvtsi2ss   4(%rsp) , %xmm4
    cvtsi2ss   8(%rsp) , %xmm9
    cvtsi2ss   -16(%rsp) , %xmm9
    cvtsi2ss   (%rdi) , %xmm9
    cvtsi2ss   (%r9) , %xmm9
	cvtsi2ss %eax, %xmm0
	cvtsi2ss %edx, %xmm0
	cvtsi2ss %edx, %xmm9


movsd_64:
	movsd	-8(%rbp), %xmm0
	movsd	16(%rbp), %xmm9
    movsd	%xmm0 , -8(%rbp)
	movsd	%xmm9 , 16(%rbp)

movss_32:
	movss	-8(%rbp), %xmm0
	movss	16(%rbp), %xmm9
    movss	%xmm0 , -8(%rbp)
	movss	%xmm9 , 16(%rbp)
    
addinst:
	addsd	-16(%rbp), %xmm0
	addsd	8(%rbp), %xmm9
	addss	-8(%rbp), %xmm0
	addss	16(%rbp), %xmm9
subinst:
	subsd	-16(%rbp), %xmm0
	subsd	8(%rbp), %xmm10
	subss	-16(%rbp), %xmm0
	subss	8(%rbp), %xmm10

mulinst:
	mulsd	-16(%rbp), %xmm0
	mulsd	8(%rbp), %xmm10
	mulss	-16(%rbp), %xmm0
	mulss	8(%rbp), %xmm10

divinst:
	divsd	-16(%rbp), %xmm0
	divsd	8(%rbp), %xmm10
	divss	-16(%rbp), %xmm0
	divss	8(%rbp), %xmm10

unpcklpsinst:
	unpcklps	%xmm0, %xmm0
	unpcklps	%xmm0, %xmm9
	unpcklps	%xmm10, %xmm0
	unpcklps	%xmm11, %xmm11
	unpcklps	8(%rsp) , %xmm0
	unpcklps	8(%rsp) , %xmm9
xorpsinst:
	xorps %xmm1, %xmm1
	xorps %xmm1, %xmm9
	xorps %xmm9, %xmm2
	xorps %xmm10, %xmm9
	xorps 4(%rbp), %xmm1
	xorps 4(%rbp), %xmm9
	xorps 4(%rsp), %xmm1
	xorps 4(%rsp), %xmm9
xorpdinst:
	xorpd %xmm1, %xmm1
	xorpd %xmm1, %xmm9
	xorpd %xmm9, %xmm2
	xorpd %xmm10, %xmm9
	xorpd 4(%rbp), %xmm1
	xorpd 4(%rbp), %xmm9
	xorpd 4(%rsp), %xmm1
	xorpd 4(%rsp), %xmm9
    

cvtps2pdinst:
	cvtps2pd	%xmm0, %xmm1
	cvtss2sd	%xmm0, %xmm1
	cvtps2pd	%xmm0, %xmm9
	cvtss2sd	%xmm0, %xmm9
	cvtps2pd	%xmm9, %xmm2
	cvtss2sd	%xmm9, %xmm2
	cvtps2pd	%xmm9, %xmm12
	cvtss2sd	%xmm9, %xmm12

	cvtps2pd	8(%rbp), %xmm0	
	cvtss2sd	8(%rbp), %xmm0	
	cvtps2pd	-16(%rbp), %xmm9
	cvtss2sd	-16(%rbp), %xmm9
	cvtps2pd	(%rdi), %xmm0	
	cvtss2sd	(%rdi), %xmm0	
	cvtps2pd	(%rdi), %xmm9
	cvtss2sd	(%rdi), %xmm9
	cvtps2pd	(%r9), %xmm9
	cvtss2sd	(%r9), %xmm9

cvtpd2psinst:
	cvtpd2ps	%xmm0, %xmm1
	cvtsd2ss	%xmm0, %xmm1
	cvtpd2ps	%xmm0, %xmm9
	cvtsd2ss	%xmm0, %xmm9
	cvtpd2ps	%xmm9, %xmm2
	cvtsd2ss	%xmm9, %xmm2
	cvtpd2ps	%xmm9, %xmm12
	cvtsd2ss	%xmm9, %xmm12

	cvtpd2ps	8(%rbp), %xmm0	
	cvtsd2ss	8(%rbp), %xmm0	
	cvtpd2ps	-16(%rbp), %xmm9
	cvtsd2ss	-16(%rbp), %xmm9
	cvtpd2ps	(%rdi), %xmm0	
	cvtsd2ss	(%rdi), %xmm0	
	cvtpd2ps	(%rdi), %xmm9
	cvtsd2ss	(%rdi), %xmm9
	cvtpd2ps	(%r9), %xmm9
	cvtsd2ss	(%r9), %xmm9

cvttss2siqinst:
	cvttss2si	%xmm0, %eax
	cvttss2si	%xmm9, %eax
	cvttss2si	%xmm0, %edx
	cvttss2si	%xmm9, %edx
	cvttss2sil	%xmm0, %eax
	cvttss2sil	%xmm9, %eax
	cvttss2sil	%xmm0, %edx
	cvttss2sil	%xmm9, %edx
	cvttss2siq	%xmm0, %rdi
	cvttss2siq	%xmm0, %r9
	cvttss2siq	%xmm9, %rdi
	cvttss2siq	%xmm9, %r10

cvttsd2siinst:
	cvttsd2sil	%xmm0, %eax
	cvttsd2sil	%xmm9, %edx
	cvttsd2si	%xmm0, %eax
	cvttsd2si	%xmm9, %edx
	cvttsd2siq	%xmm0, %rax
	cvttsd2siq	%xmm0, %r10
	cvttsd2siq	%xmm10, %rax
	cvttsd2siq	%xmm11, %r12

addop:
	addsd	300(%rbp), %xmm0
	addsd	-500(%rbp), %xmm9
	addsd	%xmm1, %xmm0
	addsd	%xmm1, %xmm9
	addsd	%xmm9, %xmm2
	addsd	%xmm9, %xmm10
	addss	300(%rbp), %xmm0
	addss	-500(%rbp), %xmm9
	addss	%xmm1, %xmm0
	addss	%xmm1, %xmm9
	addss	%xmm9, %xmm2
	addss	%xmm9, %xmm10

subop:
	subsd	300(%rbp), %xmm0
	subsd	-500(%rbp), %xmm9
	subsd	%xmm1, %xmm0
	subsd	%xmm1, %xmm9
	subsd	%xmm9, %xmm2
	subsd	%xmm9, %xmm10
	subss	300(%rbp), %xmm0
	subss	-500(%rbp), %xmm9
	subss	%xmm1, %xmm0
	subss	%xmm1, %xmm9
	subss	%xmm9, %xmm2
	subss	%xmm9, %xmm10

mulop:
	mulsd	300(%rbp), %xmm0
	mulsd	-500(%rbp), %xmm9
	mulsd	%xmm1, %xmm0
	mulsd	%xmm1, %xmm9
	mulsd	%xmm9, %xmm2
	mulsd	%xmm9, %xmm10
	mulss	300(%rbp), %xmm0
	mulss	-500(%rbp), %xmm9
	mulss	%xmm1, %xmm0
	mulss	%xmm1, %xmm9
	mulss	%xmm9, %xmm2
	mulss	%xmm9, %xmm10

divop:
	divsd	300(%rbp), %xmm0
	divsd	-500(%rbp), %xmm9
	divsd	%xmm1, %xmm0
	divsd	%xmm1, %xmm9
	divsd	%xmm9, %xmm2
	divsd	%xmm9, %xmm10
	divss	300(%rbp), %xmm0
	divss	-500(%rbp), %xmm9
	divss	%xmm1, %xmm0
	divss	%xmm1, %xmm9
	divss	%xmm9, %xmm2
	divss	%xmm9, %xmm10

movop:
	movsd	300(%rbp), %xmm0
	movsd	-500(%rbp), %xmm9
	movsd	%xmm1, %xmm0
	movsd	%xmm1, %xmm9
	movsd	%xmm9, %xmm2
	movsd	%xmm9, %xmm10
	movss	300(%rbp), %xmm0
	movss	-500(%rbp), %xmm9
	movss	%xmm1, %xmm0
	movss	%xmm1, %xmm9
	movss	%xmm9, %xmm2
	movss	%xmm9, %xmm10

ucomisdinst:
	ucomisd %xmm0, %xmm1
    ucomisd %xmm0, %xmm10
    ucomisd %xmm11, %xmm1
    ucomisd %xmm11, %xmm9
    ucomisd 8(%rsp), %xmm1
    ucomisd 8(%rsp), %xmm9
    ucomisd 8(%rbp), %xmm1
    ucomisd 8(%rbp), %xmm9

ucomissinst:
	ucomiss %xmm0, %xmm1
    ucomiss %xmm0, %xmm10
    ucomiss %xmm11, %xmm1
    ucomiss %xmm11, %xmm9
    ucomiss 8(%rsp), %xmm1
    ucomiss 8(%rsp), %xmm9
    ucomiss 8(%rbp), %xmm1
    ucomiss 8(%rbp), %xmm9

cvtsi2ssqinst:
	cvtsi2ssq   %rax, %xmm0
    cvtsi2ssq   %rdi, %xmm0
    cvtsi2ssq   %rax, %xmm13
    cvtsi2ssq   %rdi, %xmm13
    cvtsi2ssq   4(%rsp) , %xmm4
    cvtsi2ssq   8(%rsp) , %xmm9
    cvtsi2ssq   -16(%rsp) , %xmm9

