// PE/COFF object constants for x86_64 (mirror of the mother peff backend).

IMAGE_FILE_MACHINE_AMD64<i32> = 0x8664

IMAGE_SCN_CNT_CODE<u32>             = 0x00000020
IMAGE_SCN_CNT_INITIALIZED_DATA<u32> = 0x00000040
IMAGE_SCN_ALIGN_1BYTES<u32>         = 0x00100000
IMAGE_SCN_ALIGN_8BYTES<u32>         = 0x00400000
IMAGE_SCN_MEM_EXECUTE<u32>          = 0x20000000
IMAGE_SCN_MEM_READ<u32>             = 0x40000000
IMAGE_SCN_MEM_WRITE<u32>            = 0x80000000

IMAGE_REL_AMD64_ADDR64<i32> = 0x0001
IMAGE_REL_AMD64_REL32<i32>  = 0x0004

IMAGE_SYM_UNDEFINED<i32>      = 0
IMAGE_SYM_CLASS_EXTERNAL<i32> = 2
IMAGE_SYM_CLASS_STATIC<i32>   = 3
IMAGE_SYM_DTYPE_FUNCTION<i32> = 0x20

// ELF reloc type ids as recorded by the shared instruct pass.
PEFF_R_X86_64_64<i32>    = 1
PEFF_R_X86_64_PC32<i32>  = 2
PEFF_R_X86_64_PLT32<i32> = 4

// On-disk record sizes (packed layouts, serialized byte-by-byte).
COFF_FILE_HEADER_LEN<i32>    = 20
COFF_SECTION_HEADER_LEN<i32> = 40
COFF_RELOC_LEN<i32>          = 10
COFF_SYMBOL_LEN<i32>         = 18

// Round up to a multiple of 4. Avoid (v+3)&-4 — Tu bitwise on negatives
// has been observed to drop the +3 and round down (100 -> 96).
fn coff_align4(v<i32>) i32 {
    a<i32> = v + 3
    return (a / 4) * 4
}

fn coff_i32_u32(v<i32>) u32 {
    r<u32> = v
    return r
}
