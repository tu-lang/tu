main:
    movzx %al , %rax
    movzx %al , %eax
    movzx %al , %r8

    movzx %bl , %rax
    movzx %bl , %eax
    movzx %bl , %r8
    #内部
    movzx lable(%rip) , %rax
    movzx lable(%rip) , %eax
    movzx lable(%rip) , %r8
    #外部
    movzx e1(%rip) , %rax
    movzx e1(%rip) , %eax
    movzx e1(%rip) , %r8
lable:
    mov $1 , %rax

