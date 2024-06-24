pushri:
    push $100 #1字节
    push $144 
    push $257 #2字节
    push $0xaaaaaa #4字节
pushr8:
    push %rax
    push %rdi
    push %r9
    push %rbp
    push %rsp

pushm:
	push (%rsp)
	push 16(%rsp)
	push (%rax)
	push 16(%rax)
	push (%rdi)
	push 16(%rdi)
	push (%r9)
	push 16(%r9)

popr8:
    pop %rax
    pop %rdi
    pop %rbp
    pop %r8
    pop %r9
    pop %rsp
    pop %rbp
    pop (%rax)
    pop (%r9)
    pop 10(%rsp)
    pop 10(%rax)
    pop 10(%r9)
    pop -130(%r9)
    pop 130(%r9)

