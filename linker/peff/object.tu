// Load one COFF IMAGE_FILE_MACHINE_AMD64 object: .text / .data / relocs / symbols.

use linker.utils
use std
use sys
use fmt
use os
use runtime

IMAGE_FILE_MACHINE_AMD64<i32> = 0x8664
IMAGE_REL_AMD64_ADDR64<i32> = 0x0001
IMAGE_REL_AMD64_REL32<i32>  = 0x0004
IMAGE_SYM_UNDEFINED<i32>    = 0

COFF_FILE_HEADER_LEN<i32>    = 20
COFF_SECTION_HEADER_LEN<i32> = 40
COFF_RELOC_LEN<i32>          = 10
COFF_SYMBOL_LEN<i32>         = 18

PE_FILE_ALIGN<u32> = 0x200
PE_SECT_ALIGN<u32> = 0x1000
PE_SUBSYSTEM_CUI<u32> = 3
PE_OPT_MAGIC<u32> = 0x20b
PE_OPT_SIZE<i32> = 240
PE_DOS_LEN<i32> = 64

mem ObjSym {
    i32 name_off
    i32 n_sect      // 1=.text 2=.data 0=undef
    i32 value
    i32 storage
}

mem ObjRel {
    i32 address
    i32 name_off
    i32 ty
}

mem CoffObject {
    ByteBuf* text
    ByteBuf* data
    NameTab* names
    std.Array* syms
    std.Array* text_rels
    std.Array* data_rels
}

fn sect_name_is(sh<i8*>, a<i32>, b<i32>, c<i32>, d<i32>, e<i32>) i32 {
    ba<i8> = a
    bb<i8> = b
    bc<i8> = c
    bd<i8> = d
    be<i8> = e
    if sh[0] != ba {
        return 0
    }
    if sh[1] != bb {
        return 0
    }
    if sh[2] != bc {
        return 0
    }
    if sh[3] != bd {
        return 0
    }
    if sh[4] != be {
        return 0
    }
    if sh[5] != 0 {
        return 0
    }
    return 1
}

fn coff_sym_name(sym<i8*>, strtab<i8*>, dst<i8*>) i32 {
    z<u32> = ru32(sym)
    if z != 0.(u32) {
        i<i32> = 0
        while i < 8 {
            c<i8> = sym[i]
            if c == 0.(i8) {
                break
            }
            dst[i] = c
            i += 1
        }
        dst[i] = 0.(i8)
        return i
    }
    off<u32> = ru32(sym + 4)
    src<i8*> = strtab + u32_i32(off)
    i<i32> = 0
    while i < 500 {
        c<i8> = src[i]
        dst[i] = c
        if c == 0.(i8) {
            return i
        }
        i += 1
    }
    dst[500] = 0.(i8)
    return 500
}

const CoffObject::load(path) CoffObject, i32 {
    fp<i32> = utils.fopen(path, "rb")
    if fp <= 0 {
        fmt.printf("[tu/peff] cannot read %s\n", path)
        return null, 1
    }
    zero<i64> = 0
    whence_end<i64> = 2
    whence_set<i64> = 0
    sz<i64> = sys.lseek(fp, zero, whence_end)
    min_sz<i64> = 20
    if sz < min_sz {
        utils.fclose(fp)
        fmt.printf("[tu/peff] %s too small\n", path)
        return null, 1
    }
    sys.lseek(fp, zero, whence_set)
    szu<u64> = sz
    raw<u64> = runtime.malloc(szu, 1.(i8), 1.(i8))
    utils.fread_with_buf(fp, raw, sz)
    utils.fclose(fp)
    buf<i8*> = raw
    szi<i32> = u64_i32(szu)

    machine<u16> = ru16(buf)
    if machine.(i32) != IMAGE_FILE_MACHINE_AMD64 {
        fmt.printf("[tu/peff] %s is not AMD64 COFF\n", path)
        return null, 1
    }
    nsect<u16> = ru16(buf + 2)
    sym_off<u32> = ru32(buf + 8)
    nsym<u32> = ru32(buf + 12)
    opt_sz<u16> = ru16(buf + 16)
    if opt_sz.(i32) != 0 {
        fmt.printf("[tu/peff] %s unexpected optional header\n", path)
        return null, 1
    }

    text_off<u32> = 0
    text_sz<u32> = 0
    text_rel_off<u32> = 0
    text_nrel<u16> = 0
    data_off<u32> = 0
    data_sz<u32> = 0
    data_rel_off<u32> = 0
    data_nrel<u16> = 0
    text_idx<i32> = 0
    data_idx<i32> = 0

    ns<i32> = nsect.(i32)
    si<i32> = 0
    while si < ns {
        sh<i8*> = buf + COFF_FILE_HEADER_LEN + si * COFF_SECTION_HEADER_LEN
        if COFF_FILE_HEADER_LEN + (si + 1) * COFF_SECTION_HEADER_LEN > szi {
            fmt.printf("[tu/peff] %s truncated section header\n", path)
            return null, 1
        }
        if sect_name_is(sh, 46, 116, 101, 120, 116) != 0 {
            text_sz = ru32(sh + 16)
            text_off = ru32(sh + 20)
            text_rel_off = ru32(sh + 24)
            text_nrel = ru16(sh + 32)
            text_idx = si + 1
        } else if sect_name_is(sh, 46, 100, 97, 116, 97) != 0 {
            data_sz = ru32(sh + 16)
            data_off = ru32(sh + 20)
            data_rel_off = ru32(sh + 24)
            data_nrel = ru16(sh + 32)
            data_idx = si + 1
        }
        si += 1
    }

    o<CoffObject> = new CoffObject
    o.text = ByteBuf::create()
    o.data = ByteBuf::create()
    o.names = NameTab::create()
    o.syms = std.NewArray()
    o.text_rels = std.NewArray()
    o.data_rels = std.NewArray()

    if text_sz > 0.(u32) {
        toff<i32> = u32_i32(text_off)
        tlen<i32> = u32_i32(text_sz)
        if toff < 0 || toff + tlen > szi {
            fmt.printf("[tu/peff] %s .text out of range\n", path)
            return null, 1
        }
        o.text.append(buf + toff, tlen)
    }
    if data_sz > 0.(u32) {
        doff<i32> = u32_i32(data_off)
        dlen<i32> = u32_i32(data_sz)
        if doff < 0 || doff + dlen > szi {
            fmt.printf("[tu/peff] %s .data out of range\n", path)
            return null, 1
        }
        o.data.append(buf + doff, dlen)
    }

    if nsym == 0.(u32) || sym_off == 0.(u32) {
        return o, 0
    }
    soff<i32> = u32_i32(sym_off)
    nsym_i<i32> = u32_i32(nsym)
    if soff < 0 || soff + nsym_i * COFF_SYMBOL_LEN + 4 > szi {
        fmt.printf("[tu/peff] %s symbol table out of range\n", path)
        return null, 1
    }
    strtab<i8*> = buf + soff + nsym_i * COFF_SYMBOL_LEN
    strsz<u32> = ru32(strtab)
    if soff + nsym_i * COFF_SYMBOL_LEN + u32_i32(strsz) > szi {
        fmt.printf("[tu/peff] %s string table out of range\n", path)
        return null, 1
    }

    tmp<u64> = pe_zero(512)
    tbuf<i8*> = tmp
    i<u32> = 0
    while i < nsym {
        ii<i32> = u32_i32(i)
        sp<i8*> = buf + soff + ii * COFF_SYMBOL_LEN
        nlen<i32> = coff_sym_name(sp, strtab, tbuf)
        s<ObjSym> = new ObjSym
        s.name_off = o.names.intern(tbuf, nlen)
        p8<i8*> = sp + 8
        p12<i8*> = sp + 12
        s.value = u32_i32(ru32(p8))
        sn<i16> = ri16(p12)
        s.n_sect = sn.(i32)
        sc<i8> = sp[16]
        s.storage = sc.(i32)
        o.syms.push(s)
        ax<i8> = sp[17]
        aux<i32> = ax.(i32)
        if aux < 0 {
            aux = 0
        }
        i = i + 1.(u32) + aux.(u32)
    }

    err<i32> = o.load_rels(buf, szi, text_rel_off, text_nrel, o.text_rels)
    if err != 0 {
        fmt.printf("[tu/peff] %s text reloc parse failed\n", path)
        return null, 1
    }
    err = o.load_rels(buf, szi, data_rel_off, data_nrel, o.data_rels)
    if err != 0 {
        fmt.printf("[tu/peff] %s data reloc parse failed\n", path)
        return null, 1
    }
    return o, 0
}

CoffObject::load_rels(buf<i8*>, sz<i32>, reloff<u32>, nreloc<u16>, dst<std.Array>) i32 {
    n<u32> = nreloc
    if n == 0.(u32) {
        return 0
    }
    roff<i32> = u32_i32(reloff)
    n_i<i32> = u32_i32(n)
    if roff < 0 || roff + n_i * COFF_RELOC_LEN > sz {
        return 1
    }
    nsyms<i32> = this.syms.len()
    i<u32> = 0
    while i < n {
        ii<i32> = u32_i32(i)
        rp<i8*> = buf + roff + ii * COFF_RELOC_LEN
        addr<u32> = ru32(rp)
        sidx<u32> = ru32(rp + 4)
        tyu<u16> = ru16(rp + 8)
        si<i32> = u32_i32(sidx)
        if si < 0 || si >= nsyms {
            return 1
        }
        sy<ObjSym> = this.syms.addr[si]
        r<ObjRel> = new ObjRel
        r.address = u32_i32(addr)
        r.name_off = sy.name_off
        r.ty = tyu.(i32)
        dst.push(r)
        i += 1
    }
    return 0
}
