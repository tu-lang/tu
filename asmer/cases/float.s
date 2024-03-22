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
