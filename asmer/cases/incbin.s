# .incbin: raw bytes into .data (no trailing NUL; interior NUL preserved)
.global blob
blob:
    .incbin "incbin_payload.bin"
.global after
after:
    .byte 0x7a
main:
    retq
