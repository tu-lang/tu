l.call:
    call extern
    call l.1
    call *%rax
    call *%r10
    call l.call
l.1:
    mov $1, %rax
