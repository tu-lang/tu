main:
    movsbl %al , %eax
    movsbl %bl , %eax
    movsbl lable(%rip) , %eax
    movsbl e1(%rip) , %eax
lable:
    mov $1 , %rax
