main:
    movzb %al , %rax
    movzb %al , %eax
    movzb %al , %r8
    movzb (%rax), %r9
    movzb (%r8), %r9
    movzb (%r8), %rax
    movzb 10(%r8), %rax
    movzb 140(%r8), %rax

    movzb %bl , %rax
    movzb %bl , %eax
    movzb %bl , %r8
    #内部
    movzb lable(%rip) , %rax
    movzb lable(%rip) , %eax
    movzb lable(%rip) , %r8
    #外部
    movzb e1(%rip) , %rax
    movzb e1(%rip) , %eax
    movzb e1(%rip) , %r8
lable:
    movzb e1(%rip) , %r8
