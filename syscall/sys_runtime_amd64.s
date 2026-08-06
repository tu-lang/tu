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

.globl runtime_get_r12
runtime_get_r12:
    movq %r12,%rax
    ret

.globl runtime_get_r13
runtime_get_r13:
    movq %r13,%rax
    ret

.globl runtime_get_r14
runtime_get_r14:
    movq %r14,%rax
    ret

.globl runtime_get_r15
runtime_get_r15:
    movq %r15,%rax
    ret

.globl runtime_callerpc
runtime_callerpc:
    mov 8(%rbp) , %rax
    ret

.globl runtime_gcmentryptr
runtime_gcmentryptr:
    lea gc.ms.entry , %rax
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

# clone(flags, stack, ctid, fn, arg, tls)
# SysV args: rdi=flags rsi=stack rdx=ctid rcx=fn r8=arg r9=tls
# Kernel clone: rdi=flags rsi=stack rdx=parent_tid r10=child_tid r8=tls
# Tu fn args arrive on the stack — child must push arg before call *fn.
.globl runtime_clone
runtime_clone:
    mov    %rcx , %r13
    mov    %r8 , %r14
    mov    %r9 , %r12
    mov    %rdx , %r10
    xor    %rdx , %rdx
    xor    %r8 , %r8
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
    pause
    sub $0x1, %rdi
    jne rsp1
    ret

.globl runtime_osyield_sys
runtime_osyield_sys:
    mov $24 , %rax
    syscall
    ret

.globl runtime_futex
runtime_futex:
    mov %rcx , %r10
    mov $202 , %rax
    syscall
    ret

# pclntab: stub header only; linker grows .data to exact need and fills.
.data
.globl runtime_pclntab
runtime_pclntab:
    .long 0xFFFFFFF1
    .long 0x00000801
    .long 0
    .long 0
    .long 24
    .long 0
.globl runtime_pclntab_end
runtime_pclntab_end:
    .byte 0

.text
.globl runtime_pclntab_addr
runtime_pclntab_addr:
    lea runtime_pclntab(%rip), %rax
    ret

.globl runtime_pclntab_end_addr
runtime_pclntab_end_addr:
    lea runtime_pclntab_end(%rip), %rax
    ret
