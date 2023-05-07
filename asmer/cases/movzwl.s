rm2r:
    movzwl (%rax), %eax
    movzwl (%rax), %rdi
    movzwl (%r8),  %eax
    movzwl 10(%r8),  %eax
    movzwl (%r8),  %r9
    movzwl 140(%r8),  %r9
r2r:
    movzwl %ax, %eax
    movzwl %ax, %rax
