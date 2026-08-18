# RFC-107 D3.3: sized mov (movb/movw/movl) with r8-r15 bases need REX.B, not REX.W.
main:
    movb $0, (%r8)
    movb $0, (%r12)
    movb $0, 1(%r12)
    movb $0, (%r13)
    movb $0, 1(%r13)
    movl $0, (%r12)
    movl $0, 1(%r12)
    movb %al, (%r12)
    movb (%r12), %al
    movl %eax, (%r12)
    movl (%r12), %eax
    movw $0, 1(%r12)
    ret
