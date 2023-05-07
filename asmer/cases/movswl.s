rm2r:
    movswl (%rax), %eax
    movswl (%rax), %ebx
    movswl (%r8),  %eax
    movswl (%r8),  %esp
    movswl 10(%r8),  %esp
    movswl 140(%r8),  %esp
r2r:
    movswl %ax, %eax
#    movswl %ax, %ebp
