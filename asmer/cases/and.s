imr:
    and $0 ,%rsp
    and $100 , %rbp
    and $100 , %rdi
    and $100 , %edi
    and $100 , %r9
r4:
    and %edi , %eax
    and %ebx , %esi
    and %ecx , %edx
    and %edi , %esp
    and %ecx , %ebp
r8:
    and %rdi,  %rax
    and %rdi , %r8
    and %r9 , %rdi
    and %rdi , %rsp
    and %rdi , %rbp
mem:
    and %rdi , (%rsp)
    and %rdi , (%rbp)
    and %rcx , 100(%rsp)
    and %rcx , 100(%rbp)
    and %rcx , 130(%rbp)
    and %rcx , -130(%rbp)
    and %rax , (%rdi)
bigi:
    and $100, %rax
    and $192, %rax
    and $192, %eax
    and $192, %rcx
    and $192, %rdx
