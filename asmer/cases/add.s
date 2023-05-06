imr:
    add $0 ,%rsp
    add $100 , %rbp
    add $100 , %rdi
    add $100 , %edi
    add $100 , %r9
r4:
    add %edi , %eax
    add %ebx , %esi
    add %ecx , %edx
    add %edi , %esp
    add %ecx , %ebp
r8:
    add %rdi,  %rax
    add %rdi , %r8
    add %r9 , %rdi
    add %rdi , %rsp
    add %rdi , %rbp
mem:
    add %rdi , (%rsp)
    add %rdi , (%rbp)
    add %rcx , 100(%rsp)
    add %rcx , 100(%rbp)
    add %rcx , 130(%rbp)
    add %rcx , -130(%rbp)
    add %rax , (%rdi)
bigi:
    add $100, %rax
    add $192, %rax
    add $192, %eax
    add $192, %rcx
    add $192, %rdx
trbp:
    add $0 , (%rbp)
    add $0x4 , (%rbp)
    add $0x4 , 10(%rbp)
    add $0x48 , (%rbp)
    add $-128 , (%rbp)
    addq $128 , (%rbp)
    addq $0xaaaaaa , (%rbp)
    addq $0xaaaaaa , 10(%rbp)
trsp:
    add $0 , (%rsp)
    add $0x4 , (%rsp)
    add $0x4 , 10(%rsp)
    add $0x48 , (%rsp)
    add $-128 , (%rsp)
    addq $128 , (%rsp)
    addq $128 , 10(%rsp)
    addq $0xaaaaaa , (%rsp)
    addq $0xaaaaaa , 130(%rsp)
    addq $0xaaaaaa , -130(%rsp)
