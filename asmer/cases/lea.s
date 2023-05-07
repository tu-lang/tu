mem:
    lea test(%rip), %rsi
    lea extern1(%rip), %rsi
    lea 16(%rsp), %rsi
    lea 32(%rbp), %rax
test:
    lea 16(%rax) , %rax
    lea -16(%rax) , %r9
    lea 16(%r9) , %rdx
    lea -16(%r9) , %r8
    lea 130(%r9) , %r8
    lea -140(%r9) , %r8
test1:
    lea mem(%rip) ,%rdx
    lea test(%rip) ,%rdx

