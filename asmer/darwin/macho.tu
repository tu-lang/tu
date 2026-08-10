// Mach-O 64 constants and on-disk structs for MH_OBJECT (x86_64).

use runtime
use std

MH_MAGIC_64<u32> = 0xfeedfacf
CPU_TYPE_X86_64<u32> = 0x01000007
CPU_SUBTYPE_X86_64_ALL<u32> = 3
MH_OBJECT<u32> = 0x1
MH_EXECUTE<u32> = 0x2

MH_NOUNDEFS<u32> = 0x1
MH_DYLDLINK<u32> = 0x4
MH_TWOLEVEL<u32> = 0x80

LC_SEGMENT_64<u32> = 0x19
LC_SYMTAB<u32> = 0x2
LC_DYSYMTAB<u32> = 0xb

S_REGULAR<u32> = 0x0
S_ATTR_PURE_INSTRUCTIONS<u32> = 0x80000000
S_ATTR_SOME_INSTRUCTIONS<u32> = 0x400

N_UNDF<u8> = 0x0
N_ABS<u8> = 0x2
N_SECT<u8> = 0xe
N_EXT<u8> = 0x1
N_TYPE<u8> = 0xe
NO_SECT<u8> = 0

X86_64_RELOC_UNSIGNED<u32> = 0
X86_64_RELOC_SIGNED<u32> = 1
X86_64_RELOC_BRANCH<u32> = 2

R_X86_64_64<i32> = 1
R_X86_64_PC32<i32> = 2
R_X86_64_PLT32<i32> = 4

MACH_HEADER64_LEN<i32> = 32
SEGMENT_COMMAND64_LEN<i32> = 72
SECTION64_LEN<i32> = 80
SYMTAB_COMMAND_LEN<i32> = 24
DYSYMTAB_COMMAND_LEN<i32> = 80
NLIST64_LEN<i32> = 16

mem MachHeader64 {
    u32 magic
    u32 cputype
    u32 cpusubtype
    u32 filetype
    u32 ncmds
    u32 sizeofcmds
    u32 flags
    u32 reserved
}

mem SegmentCommand64 {
    u32 cmd
    u32 cmdsize
    i8  segname[16]
    u64 vmaddr
    u64 vmsize
    u64 fileoff
    u64 filesize
    u32 maxprot
    u32 initprot
    u32 nsects
    u32 flags
}

mem Section64 {
    i8  sectname[16]
    i8  segname[16]
    u64 addr
    u64 size
    u32 offset
    u32 align
    u32 reloff
    u32 nreloc
    u32 flags
    u32 reserved1
    u32 reserved2
    u32 reserved3
}

mem SymtabCommand {
    u32 cmd
    u32 cmdsize
    u32 symoff
    u32 nsyms
    u32 stroff
    u32 strsize
}

mem DysymtabCommand {
    u32 cmd
    u32 cmdsize
    u32 ilocalsym
    u32 nlocalsym
    u32 iextdefsym
    u32 nextdefsym
    u32 iundefsym
    u32 nundefsym
    u32 tocoff
    u32 ntoc
    u32 modtaboff
    u32 nmodtab
    u32 extrefsymoff
    u32 nextrefsyms
    u32 indirectsymoff
    u32 nindirectsyms
    u32 extreloff
    u32 nextrel
    u32 locreloff
    u32 nlocrel
}

mem Nlist64 {
    u32 n_strx
    u8  n_type
    u8  n_sect
    u16 n_desc
    u64 n_value
}

fn i32_u64(v<i32>) u64 {
    r<u64> = v
    return r
}
fn i32_u32(v<i32>) u32 {
    r<u32> = v
    return r
}

// Noscan zeroed bytes for on-disk Mach-O structs (must not live on the GC heap).
fn macho_zero(n<i32>) u64 {
    n64<u64> = n
    z<u64> = 0
    if n <= 0 {
        return z
    }
    bits<u64> = runtime.malloc(n64, 1.(i8), 1.(i8))
    std.memset(bits, 0, n64)
    return bits
}
fn i32_u8(v<i32>) i8 {
    t<i32> = v & 255
    r<i8> = t
    return r
}
fn u32_i32(v<u32>) i32 {
    r<i32> = v
    return r
}

// Write up to 10 ASCII bytes at base+off; 0 stops (rest already zero).
fn poke_cstr(base<u64>, off<i32>, c0<i32>, c1<i32>, c2<i32>, c3<i32>, c4<i32>, c5<i32>, c6<i32>, c7<i32>, c8<i32>, c9<i32>) {
    p<i8*> = base
    d<i8*> = p + off
    if c0 == 0 { return }
    d[0] = i32_u8(c0)
    if c1 == 0 { return }
    d[1] = i32_u8(c1)
    if c2 == 0 { return }
    d[2] = i32_u8(c2)
    if c3 == 0 { return }
    d[3] = i32_u8(c3)
    if c4 == 0 { return }
    d[4] = i32_u8(c4)
    if c5 == 0 { return }
    d[5] = i32_u8(c5)
    if c6 == 0 { return }
    d[6] = i32_u8(c6)
    if c7 == 0 { return }
    d[7] = i32_u8(c7)
    if c8 == 0 { return }
    d[8] = i32_u8(c8)
    if c9 == 0 { return }
    d[9] = i32_u8(c9)
}

// Pack relocation_info into 8 little-endian bytes (avoid bitfield ABI).
fn reloc_pack(out<i8*>, address<i32>, symbolnum<u32>, pcrel<i32>, length<i32>, ext<i32>, ty<u32>) {
    out[0] = i32_u8(address)
    out[1] = i32_u8(address >> 8)
    out[2] = i32_u8(address >> 16)
    out[3] = i32_u8(address >> 24)
    pc<u32> = pcrel
    ln<u32> = length
    ex<u32> = ext
    w<u32> = (symbolnum & 0xffffff)
                 | ((pc & 1) << 24)
                 | ((ln & 3) << 25)
                 | ((ex & 1) << 27)
                 | ((ty & 0xf) << 28)
    wi<i32> = u32_i32(w)
    out[4] = i32_u8(wi)
    out[5] = i32_u8(wi >> 8)
    out[6] = i32_u8(wi >> 16)
    out[7] = i32_u8(wi >> 24)
}

// Unpack 8-byte relocation_info. Returns address, symbolnum, pcrel, length, ext, type.
fn reloc_unpack(src<i8*>) i32, u32, i32, i32, i32, u32 {
    b<u8*> = src
    b0<u32> = b[0]
    b1<u32> = b[1]
    b2<u32> = b[2]
    b3<u32> = b[3]
    b4<u32> = b[4]
    b5<u32> = b[5]
    b6<u32> = b[6]
    b7<u32> = b[7]
    mixed<u32> = b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
    address<i32> = u32_i32(mixed)
    w<u32> = b4 | (b5 << 8) | (b6 << 16) | (b7 << 24)
    symbolnum<u32> = w & 0xffffff
    pcrel<i32> = u32_i32((w >> 24) & 1)
    length<i32> = u32_i32((w >> 25) & 3)
    ext<i32> = u32_i32((w >> 27) & 1)
    ty<u32> = (w >> 28) & 0xf
    return address, symbolnum, pcrel, length, ext, ty
}
