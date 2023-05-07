main:
    movzbl %al , %rax
    movzbl %al , %eax
    movzbl %al , %r8
    movzbl (%rax), %r9
    movzbl (%rax), %eax
    movzbl (%r8), %r9
    movzbl (%r8), %rax
    movzbl 10(%r8), %rax
    movzbl 140(%r8), %rax
    movzbl %bl , %rax
    movzbl %bl , %eax
    movzbl %bl , %r8
    movzbl lable(%rip) , %rax
    movzbl lable(%rip) , %eax
    movzbl lable(%rip) , %r8
    movzbl e1(%rip) , %rax
    movzbl e1(%rip) , %eax
    movzbl e1(%rip) , %r8
lable:
    mov $1 , %rax

