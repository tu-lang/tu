imm:
    cmp $1,%rax
    cmp $0,%eax
rr:
    cmp %rdi,%rax
    cmp %edi,%eax
    cmp %rsi,%rdi
    
common:
    cmp    $-129,%rax
    cmp    $-129,%eax
    cmp    $-129,%rcx
    cmp    $-129,%ecx
    cmp    $127,%rax
    cmp    $127,%eax
    cmp    $127,%rcx
    cmp    $127,%ecx
    cmp    $128,%rax
    cmp    $128,%eax
    cmp    $128,%rcx
    cmp    $128,%ecx
    cmp    $0xff,%rax
    cmp    $0xff,%eax
    cmp    $0xff,%rcx
    cmp    $0xff,%ecx
    cmp    $0xffffffff,%eax
    cmp    $0xffffffff,%ecx
    cmp    $0xfffffffffffff001,%rax
    cmp    $0xfffffffffffff001,%eax
    cmp    $0xfffffffffffff001,%rcx
    cmp    $0xfffffffffffff001,%ecx

r2m:
    cmp $1 , %rax
    cmp $192 , %rax
    cmp $1 , 16(%rax)
    cmpq $192 , 16(%rax)