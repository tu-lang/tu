// Load one MH_OBJECT: section bytes, nlist names, and per-section relocs.

use linker.utils
use std
use sys
use fmt
use os
use runtime

mem ObjSym {
    i32 name_off
    u8  n_type
    u8  n_sect
    u64 sect_off
}

mem ObjRel {
    i32 address
    i32 name_off
    u32 ty
    i32 pcrel
    i32 length
}

mem MachObject {
    ByteBuf* text
    ByteBuf* data
    NameTab* names
    std.Array* syms
    std.Array* text_rels
    std.Array* data_rels
}

fn ru32(src<i8*>) u32 {
    b<u8*> = src
    b0<u32> = b[0]
    b1<u32> = b[1]
    b2<u32> = b[2]
    b3<u32> = b[3]
    return b0 | (b1 << 8) | (b2 << 16) | (b3 << 24)
}

fn ru64(p<i8*>) u64 {
    lo<u64> = ru32(p)
    hi<u64> = ru32(p + 4)
    return lo | (hi << 32)
}

// Match __xxxx at the start of a section_64 (sectname[0..5] == '__' + 4 ascii).
fn name16_eq(field<i8*>, c2<i32>, c3<i32>, c4<i32>, c5<i32>) i32 {
    if field[0] != '_' {
        return 0
    }
    if field[1] != '_' {
        return 0
    }
    b2<i8> = c2
    b3<i8> = c3
    b4<i8> = c4
    b5<i8> = c5
    if field[2] != b2 {
        return 0
    }
    if field[3] != b3 {
        return 0
    }
    if field[4] != b4 {
        return 0
    }
    if field[5] != b5 {
        return 0
    }
    return 1
}

const MachObject::load(path) MachObject, i32 {
    fp<i32> = utils.fopen(path, "rb")
    if fp <= 0 {
        fmt.printf("[tu/darwin] cannot read %s\n", path)
        return null, 1
    }
    zero<i64> = 0
    whence_end<i64> = 2
    whence_set<i64> = 0
    sz<i64> = sys.lseek(fp, zero, whence_end)
    min_sz<i64> = 32
    if sz < min_sz {
        utils.fclose(fp)
        fmt.printf("[tu/darwin] %s too small\n", path)
        return null, 1
    }
    sys.lseek(fp, zero, whence_set)
    szu<u64> = sz
    raw<u64> = runtime.malloc(szu, 1.(i8), 1.(i8))
    utils.fread_with_buf(fp, raw, sz)
    utils.fclose(fp)
    buf<i8*> = raw

    magic<u32> = ru32(buf)
    ftype<u32> = ru32(buf + 12)
    ncmds<u32> = ru32(buf + 16)
    if magic != MH_MAGIC_64 || ftype != MH_OBJECT {
        fmt.printf("[tu/darwin] %s is not Mach-O MH_OBJECT\n", path)
        return null, 1
    }

    text_addr<u64> = 0
    data_addr<u64> = 0
    text_off<u32> = 0
    data_off<u32> = 0
    text_sz<u32> = 0
    data_sz<u32> = 0
    text_reloff<u32> = 0
    text_nreloc<u32> = 0
    data_reloff<u32> = 0
    data_nreloc<u32> = 0
    symoff<u32> = 0
    nsyms<u32> = 0
    stroff<u32> = 0
    strsize<u32> = 0

    pos<i32> = MACH_HEADER64_LEN
    szi<i32> = u64_i32(szu)
    ci<u32> = 0
    while ci < ncmds {
        if pos + 8 > szi {
            fmt.printf("[tu/darwin] %s truncated load command\n", path)
            return null, 1
        }
        cmd<u32> = ru32(buf + pos)
        cmdsize<u32> = ru32(buf + pos + 4)
        csz<i32> = u32_i32(cmdsize)
        if cmdsize < 8 || pos + csz > szi {
            fmt.printf("[tu/darwin] %s bad cmdsize\n", path)
            return null, 1
        }
        if cmd == LC_SEGMENT_64 {
            nsects<u32> = ru32(buf + pos + 64)
            sp<i8*> = buf + pos + SEGMENT_COMMAND64_LEN
            si<u32> = 0
            while si < nsects {
                si_i<i32> = u32_i32(si)
                secp<i8*> = sp + si_i * SECTION64_LEN
                if name16_eq(secp, 116, 101, 120, 116) {
                    text_addr = ru64(secp + 32)
                    text_off = ru32(secp + 48)
                    tsz<u64> = ru64(secp + 40)
                    text_sz = u64_u32(tsz)
                    text_reloff = ru32(secp + 56)
                    text_nreloc = ru32(secp + 60)
                } else if name16_eq(secp, 100, 97, 116, 97) {
                    data_addr = ru64(secp + 32)
                    data_off = ru32(secp + 48)
                    dsz<u64> = ru64(secp + 40)
                    data_sz = u64_u32(dsz)
                    data_reloff = ru32(secp + 56)
                    data_nreloc = ru32(secp + 60)
                }
                si += 1
            }
        } else if cmd == LC_SYMTAB {
            symoff = ru32(buf + pos + 8)
            nsyms = ru32(buf + pos + 12)
            stroff = ru32(buf + pos + 16)
            strsize = ru32(buf + pos + 20)
        }
        pos = pos + csz
        ci += 1
    }

    szu32<u32> = u64_u32(szu)
    if text_off + text_sz > szu32 || data_off + data_sz > szu32 {
        fmt.printf("[tu/darwin] %s section out of range\n", path)
        return null, 1
    }

    o<MachObject> = new MachObject
    o.text = ByteBuf::create()
    o.data = ByteBuf::create()
    o.syms = std.NewArray()
    o.text_rels = std.NewArray()
    o.data_rels = std.NewArray()
    if text_sz > 0 {
        toff<i32> = u32_i32(text_off)
        tlen<i32> = u32_i32(text_sz)
        o.text.append(buf + toff, tlen)
    }
    if data_sz > 0 {
        doff<i32> = u32_i32(data_off)
        dlen<i32> = u32_i32(data_sz)
        o.data.append(buf + doff, dlen)
    }

    if stroff + strsize > szu32 {
        fmt.printf("[tu/darwin] %s symtab out of range\n", path)
        return null, 1
    }
    soff<i32> = u32_i32(stroff)
    strtab<i8*> = buf + soff
    ssize<i32> = u32_i32(strsize)
    o.names = NameTab::from_bytes(strtab, ssize)
    i<u32> = 0
    while i < nsyms {
        ii<i32> = u32_i32(i)
        syoff<i32> = u32_i32(symoff)
        nlp<i8*> = buf + syoff + ii * NLIST64_LEN
        n_strx<u32> = ru32(nlp)
        if n_strx >= strsize {
            fmt.printf("[tu/darwin] bad n_strx in %s\n", path)
            return null, 1
        }
        s<ObjSym> = new ObjSym
        nstrx<i32> = u32_i32(n_strx)
        s.name_off = nstrx
        s.n_type = nlp[4]
        s.n_sect = nlp[5]
        n_value<u64> = ru64(nlp + 8)
        if s.n_sect == 1 {
            s.sect_off = n_value - text_addr
        } else if s.n_sect == 2 {
            s.sect_off = n_value - data_addr
        } else {
            s.sect_off = 0
        }
        o.syms.push(s)
        i += 1
    }

    err<i32> = o.load_rels(buf, szi, text_reloff, text_nreloc, o.text_rels)
    if err != 0 {
        fmt.printf("[tu/darwin] %s reloc parse failed\n", path)
        return null, 1
    }
    err = o.load_rels(buf, szi, data_reloff, data_nreloc, o.data_rels)
    if err != 0 {
        fmt.printf("[tu/darwin] %s reloc parse failed\n", path)
        return null, 1
    }
    return o, 0
}

MachObject::load_rels(buf<i8*>, sz<i32>, reloff<u32>, nreloc<u32>, dst<std.Array>) i32 {
    if nreloc == 0 {
        return 0
    }
    szu<u32> = sz
    if reloff + nreloc * 8 > szu {
        return 1
    }
    i<u32> = 0
    while i < nreloc {
        ii<i32> = u32_i32(i)
        roff<i32> = u32_i32(reloff)
        rp<i8*> = buf + roff + ii * 8
        address<i32> = 0
        symbolnum<u32> = 0
        pcrel<i32> = 0
        length<i32> = 0
        ext<i32> = 0
        ty<u32> = 0
        address, symbolnum, pcrel, length, ext, ty = reloc_unpack(rp)
        nsym_i<i32> = this.syms.len()
        nsym<u32> = nsym_i
        if symbolnum >= nsym {
            return 1
        }
        sidx<i32> = u32_i32(symbolnum)
        sy<ObjSym> = this.syms.addr[sidx]
        r<ObjRel> = new ObjRel
        r.address = address
        r.name_off = sy.name_off
        r.ty = ty
        r.pcrel = pcrel
        r.length = length
        dst.push(r)
        i += 1
    }
    return 0
}
