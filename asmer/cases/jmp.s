main:
    jmp test
    jmp test
test:
    jmp main
    mov $1 , %rax
    jmp extern
    jmp long_end
long_jmp: 
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
long_end:
    mov $20 , %rax  # 140字节
    jmp long_jmp
    
