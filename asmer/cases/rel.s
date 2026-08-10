.global func
func: 
    lea out1(%rip), %rax
    mov out2(%rip), %rax
    mov %rax, out2(%rip)
    movq %rcx, out1(%rip)
    mov out1(%rip), %r8
    mov %r8, out2(%rip)
