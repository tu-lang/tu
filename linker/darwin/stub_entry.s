# Darwin crt entry.
# Tu codegen emits main_main / main_init.0; the loader looks for _main.
# Mnemonics must be accepted by the asmer (push/mov/call/xor/pop/ret).

.text
.globl _main
_main:
    push %rbp
    mov %rsp, %rbp
    call main_init.0
    call main_main
    xor %eax, %eax
    pop %rbp
    ret
