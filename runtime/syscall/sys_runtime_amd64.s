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
