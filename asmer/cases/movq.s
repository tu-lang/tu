r8:
    movq %rsp , %rax
    movq %rbp , %rax
    movq %rdi , %rax
    movq %rsi , %rax
    movq %rdx , %rax
    movq %rcx , %rax
    movq %r8 , %rax
    movq %r9 , %rax
    movq %rax , %rax
    movq %rbx , %rax
    movq	$4730986895511650304, %rax
    movabsq	$4730986895511650304, %rax

float:
	movq	-8(%rbp), %xmm0
	movq	16(%rbp), %xmm9
    movq	%xmm0 , -8(%rbp)
	movq	%xmm9 , 16(%rbp)
    movq    %rax,     %xmm0
    movq    %r8,      %xmm12
    movq    %xmm0 , %rax
    movq    %xmm12, %r8
