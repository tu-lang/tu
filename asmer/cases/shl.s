main:
    shl %cl,%eax
    shl %cl,%edi
    shl %cl,%ch
    shl %cl,%bh
    shl %cl,%rax
    shl %cl,%rcx
    shl %cl,%rsp
    shl %cl,%rdi
    shl %cl,%r8
im:
    shl $0,%rax
    shl $0,%rdi
    shl $100, %r8
    shl $100, %eax
    shl $192, %rax

