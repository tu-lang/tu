.text
.globl runtime_gc_get_sp
runtime_gc_get_sp:
    movq %rsp,%rax
    ret

.globl runtime_gc_get_bp
runtime_gc_get_bp:
    movq %rbp,%rax
    ret

.globl runtime_gc_get_di
runtime_gc_get_di:
    movq %rdi,%rax
    ret

.globl runtime_gc_get_si
runtime_gc_get_si:
    movq %rsi,%rax
    ret

.globl runtime_gc_get_dx
runtime_gc_get_dx:
    movq %rdx,%rax
    ret

.globl runtime_gc_get_cx
runtime_gc_get_cx:
    movq %rcx,%rax
    ret

.globl runtime_gc_get_r8
runtime_gc_get_r8:
    movq %r8,%rax
    ret

.globl runtime_gc_get_r9
runtime_gc_get_r9:
    movq %r9,%rax
    ret

.globl runtime_gc_get_ax
runtime_gc_get_ax:
    movq %rax,%rax
    ret

.globl runtime_gc_get_bx
runtime_gc_get_bx:
    movq %rbx,%rax
    ret

.globl runtime_callerpc
runtime_callerpc:
    mov 8(%rbp) , %rax
    ret

runtime_sys_settls:
    add    $0x8,%rdi   
    mov    %rdi,%rsi
    mov    $0x1002,%rdi
    mov    $0x9e,%rax  
    syscall 
    cmp    $0xfffffffffffff001,%rax
    jbe    runtime_sys_settls_ret
    mov    $101 , %edi
    mov    $60 , %rax
    syscall
    #movl   $0xf1,0xf1
runtime_sys_settls_ret:
    retq   

.globl runtime_sys_clone
runtime_sys_clone: 
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
    call   runtime_sys_settls
    mov    %r14 , %rdi
    call  *%r13
tc2:
    mov    $0 , %edi
    mov    $60 , %rax
    syscall
    jmp tc2

.global runtime_sys_core
runtime_sys_core:
    #GCTODO:
    #movq  %fs:0xfffffffffffffff0,%rax
    retq

.global runtime_sys_setcore
runtime_sys_setcore:
    #GCTODO:
    #movq  %rdi,%fs:0xfffffffffffffff0
    retq

.globl runtime_sys_procyield
runtime_sys_procyield:
rsp1:
    #GCTODO:
    #pause
    sub $0x1, %eax
    jne rsp1
    ret

.globl runtime_sys_osyield
runtime_sys_osyield:
    mov $24 , %rax
    syscall
    ret

.globl runtime_sys_futex
runtime_sys_futex:
    mov %rcx , %r10
    mov $202 , %rax
    syscall
    ret
