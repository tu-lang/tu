# .balign / .align / .p2align pad .data after odd-sized .string
.global oddstr
oddstr:
    .string "x"
.balign 8
.global aligned8
aligned8:
    .quad 0
.global odd2
odd2:
    .string "ab"
.align 4
.global aligned4
aligned4:
    .long 0
.p2align 3
.global aligned_p2
aligned_p2:
    .quad 1
.balign 8
.global already8
already8:
    .byte 0
main:
    retq
