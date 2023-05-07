imr:
    sub $0 ,%rsp
    sub $100 , %rbp
    sub $100 , %rdi
    sub $100 , %edi
    sub $100 , %r9
r4:
    sub %edi , %eax
    sub %ebx , %esi
    sub %ecx , %edx
    sub %edi , %esp
    sub %ecx , %ebp
r8:
    sub %rdi,  %rax
    sub %rdi , %r8
    sub %r9 , %rdi
    sub %rdi , %rsp
    sub %rdi , %rbp
mem:
    sub %rdi , (%rsp)
    sub %rdi , (%rbp)
    sub %rcx , 100(%rsp)
    sub %rcx , 130(%rsp)
    sub %rcx , -130(%rsp)
    sub %rcx , 100(%rbp)
    sub %rax , (%rdi)
bigi:
    sub $100, %rax
    sub $192, %rax
    sub $192, %eax
    sub $192, %rcx
    sub $192, %rdx
