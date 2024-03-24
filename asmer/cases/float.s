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