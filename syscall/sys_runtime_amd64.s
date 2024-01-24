.text
.globl runtime_get_sp
runtime_get_sp:
    movq %rsp,%rax
    ret

.globl runtime_get_bp
runtime_get_bp:
    movq %rbp,%rax
    ret

.globl runtime_get_di
runtime_get_di:
    movq %rdi,%rax
    ret

.globl runtime_get_si
runtime_get_si:
    movq %rsi,%rax
    ret

.globl runtime_get_dx
runtime_get_dx:
    movq %rdx,%rax
    ret

.globl runtime_get_cx
runtime_get_cx:
    movq %rcx,%rax
    ret

.globl runtime_get_r8
runtime_get_r8:
    movq %r8,%rax
    ret

.globl runtime_get_r9
runtime_get_r9:
    movq %r9,%rax
    ret

.globl runtime_get_ax
runtime_get_ax:
    movq %rax,%rax
    ret

.globl runtime_get_bx
runtime_get_bx:
    movq %rbx,%rax
    ret

.globl runtime_callerpc
runtime_callerpc:
    mov 8(%rbp) , %rax
    ret

.globl runtime_settls
runtime_settls:
    add    $0x8,%rdi   
    mov    %rdi,%rsi
    mov    $0x1002,%rdi
    mov    $0x9e,%rax  
    syscall 
    cmp    $0xfffffffffffff001,%rax
    jbe    runtime_settls_ret
    mov    $101 , %edi
    mov    $60 , %rax
    syscall
    #movl   $0xf1,0xf1
runtime_settls_ret:
    retq   

.globl runtime_clone
runtime_clone: 
    mov    %rdx , %r12
    mov    %rcx , %r13
    mov    %r8 , %r14
    mov    $56, %rax
    syscall
    cmp    $0x0,%rax
    je     tc1
    retq
tc1:
    mov    %rsi,%rsp
    mov    %r12 , %rdi
    call   runtime_settls
    push   %r14
    call  *%r13
    pop    %rdi
tc2:
    mov    $0 , %edi
    mov    $60 , %rax
    syscall
    jmp tc2

.global runtime_core
runtime_core:
    movq  %fs:0xfffffffffffffff0,%rax
    retq

.global runtime_setcore
runtime_setcore:
    movq  %rdi,%fs:0xfffffffffffffff0
    retq

.globl runtime_procyield
runtime_procyield:
rsp1:
    #GCTODO:
    #pause
    sub $0x1, %eax
    jne rsp1
    ret

.globl runtime_osyield
runtime_osyield:
    mov $24 , %rax
    syscall
    ret

.globl runtime_futex
runtime_futex:
    mov %rcx , %r10
    mov $202 , %rax
    syscall
    ret
