# PE crt entry for Phase W1 -nostd smoke.
# Tu codegen emits main_main / main_init.0; Win64 process entry is mainCRTStartup.
# ExitProcess is resolved from kernel32.lib. Shadow space: 32 bytes after aligned rbp frame.

.text
.globl mainCRTStartup
mainCRTStartup:
    push %rbp
    mov %rsp, %rbp
    sub $32, %rsp
    call main_init.0
    call main_main
    xor %ecx, %ecx
    call ExitProcess
