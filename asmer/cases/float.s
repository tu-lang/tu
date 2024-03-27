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

cvtps2pdinst:
	cvtps2pd	%xmm0, %xmm1
	cvtps2pd	%xmm0, %xmm9
	cvtps2pd	%xmm9, %xmm2
	cvtps2pd	%xmm9, %xmm12

	cvtps2pd	8(%rbp), %xmm0	
	cvtps2pd	-16(%rbp), %xmm9
	cvtps2pd	(%rdi), %xmm0	
	cvtps2pd	(%rdi), %xmm9
	cvtps2pd	(%r9), %xmm9

cvtpd2psinst:
	cvtpd2ps	%xmm0, %xmm1
	cvtpd2ps	%xmm0, %xmm9
	cvtpd2ps	%xmm9, %xmm2
	cvtpd2ps	%xmm9, %xmm12

	cvtpd2ps	8(%rbp), %xmm0	
	cvtpd2ps	-16(%rbp), %xmm9
	cvtpd2ps	(%rdi), %xmm0	
	cvtpd2ps	(%rdi), %xmm9
	cvtpd2ps	(%r9), %xmm9

cvttss2siqinst:
	cvttss2si	%xmm0, %eax
	cvttss2si	%xmm9, %eax
	cvttss2si	%xmm0, %edx
	cvttss2si	%xmm9, %edx
	cvttss2siq	%xmm0, %rdi
	cvttss2siq	%xmm0, %r9
	cvttss2siq	%xmm9, %rdi
	cvttss2siq	%xmm9, %r10

cvttsd2siinst:
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