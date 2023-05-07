main:
    cmp $0,%eax
    je .L.TRUE.007
    mov $1, %rax
.L.TRUE.006:
    mov %eax,%ebx
.L.TRUE.007:
    cmp $1,%eax
    je .L.TRUE.006
    je L2
    je L1
L1:
    mov $1 , %rax  # 7字节
    mov $2 , %rax
    mov $3 , %rax
    mov $4 , %rax
    mov $5 , %rax
    mov $6 , %rax
    mov $7 , %rax
    mov $8 , %rax
    mov $9 , %rax
    mov $10 , %rax
    mov $11 , %rax
    mov $12 , %rax
    mov $13 , %rax
    mov $14 , %rax
    mov $15 , %rax
    mov $16 , %rax
    mov $17 , %rax 
    mov $18 , %rax  
    mov $19 , %rax  
L2:
    mov $20 , %rax
