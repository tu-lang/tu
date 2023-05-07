main:
    mov %al,%bl
    mov %eax,%ecx
    mov %rax ,%rcx
    mov %r8 ,%r9
    mov %r8 ,%rax
    mov %rax ,%r8
    mov $1  ,%rax
    mov $300  ,%rax
    mov $100 , %r9
r1:
    mov %al, (%rdi)
    mov %ax, (%rdi)
    sub %al, (%rdi)
    add %al, (%rdi)
    mov %rax, (%rdi)
    mov %rax, 10(%rdi)
    mov %rax, 130(%rdi)
    mov (%rdi), %rax
    mov 10(%rdi), %rax
    mov 130(%rdi), %rax
bigim:
    mov $11887393157837578923,%rdx
    mov $-1 , %rax
    mov $-4250523714016506264,%rsi
    mov $2147483647 , %rax # int max
    mov $1010521725724951834,%rdx
    mov $-2147483648,%rax

r4:
    mov $0 , %eax
    mov $0 , %ebx
