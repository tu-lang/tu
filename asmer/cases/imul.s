main1:
    imul $8 ,%rax
    imul $8 ,%r9
    imul $8 ,%eax
main2:
    imul %rdi , %rax
    imul %rdi , %r8
    imul %r8   , %rax
    mov  %r8   , %rax
    imul %edi , %eax
bigi:
    imul $100, %rax
    imul $192, %rax
    imul $192, %eax
    imul $192, %rcx
    imul $192, %rdx
