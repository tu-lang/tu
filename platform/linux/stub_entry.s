# Linux ELF entry for -nostd builds (no std package, no runtime).
# Tu codegen emits main_main / main_init.0; the ELF linker enters at main.
# Raw process entry has no return address, so leave via exit_group(0).

.text
.globl main
main:
    call main_init.0
    call main_main
    mov $231,%rax
    xor %rdi,%rdi
    syscall
