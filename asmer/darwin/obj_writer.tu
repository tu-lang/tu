// Emit MH_OBJECT from Parser instruct bytes + ElfFile relTab.
// Adapter is dynamic so asmer.asm can call without a typed cycle.

use asmer.ast
use asmer.elf
use asmer.parser
use asmer.instruct
use asmer.utils
use std
use std.map
use string
use fmt
use os

// One nlist candidate before local/extdef/undef merge.
mem ObjSym {
    string.String* name
    u8  n_type
    u8  n_sect
    u64 n_value
    i32 is_undef
    i32 is_ext
}

mem RelOut {
    i32  address
    u32  symbolnum
    i32  pcrel
    i32  length
    i32  ext
    u32  ty
}

mem MachObjWriter {
    ByteBuf* text
    ByteBuf* data
    std.Array* local_syms
    std.Array* ext_syms
    std.Array* undef_syms
    std.Array* all_syms
    map.Map*   sym_index
    std.Array* text_rels
    std.Array* data_rels
    i64  fd
    i32  wr_off
}

fn mapstringhashkey(k<string.String>) u64 {
    return k.hash64()
}

const MachObjWriter::create() MachObjWriter {
    w<MachObjWriter> = new MachObjWriter
    w.text = ByteBuf::create()
    w.data = ByteBuf::create()
    w.local_syms = std.NewArray()
    w.ext_syms = std.NewArray()
    w.undef_syms = std.NewArray()
    w.all_syms = std.NewArray()
    w.sym_index = map.map_new(mapstringhashkey.(u64), 0.(i8))
    w.text_rels = std.NewArray()
    w.data_rels = std.NewArray()
    w.fd = 0
    w.wr_off = 0
    return w
}

MachObjWriter::collect_text(ps<parser.Parser>) {
    i<i32> = 0
    while i < ps.funcs.len() {
        fc<ast.Function> = ps.funcs.addr[i]
        j<i32> = 0
        while j < fc.instructs.len() {
            inst<instruct.Instruct> = fc.instructs.addr[j]
            if inst.size > 0 {
                this.text.append(&inst.bytes, inst.size)
            }
            j += 1
        }
        i += 1
    }
}

MachObjWriter::collect_data(ps<parser.Parser>) {
    need<i32> = ps.data_size
    if need < 0 {
        need = 0
    }
    this.data.reserve(need)
    this.data.len = need
    if need > 0 {
        need64<u64> = need
        std.memset(this.data.bits(), 0, need64)
    }
    ds<std.Array> = ps.symtable.data_symbol
    i<i32> = 0
    while i < ds.len() {
        sym<ast.Sym> = ds.addr[i]
        off<i32> = sym.addr
        if sym.isbin {
            slen<i32> = sym.bin_len
            j<i32> = 0
            while j < slen {
                if off + j < this.data.len {
                    slot<i8*> = this.data.ptr() + off + j
                    src<i8*> = sym.bin_ptr
                    *slot = src[j]
                }
                j += 1
            }
        } else if sym.isstr {
            slen<i32> = sym.str.len()
            j<i32> = 0
            while j < slen {
                if off + j < this.data.len {
                    slot<i8*> = this.data.ptr() + off + j
                    src<i8*> = sym.str.str()
                    *slot = src[j]
                }
                j += 1
            }
            if off + slen < this.data.len {
                z<i8*> = this.data.ptr() + off + slen
                *z = 0
            }
        } else {
            pos<i32> = off
            j<i32> = 0
            while j < sym.datas.len() {
                b<ast.ByteBlock> = sym.datas.addr[j]
                if b.type == ast.KW_ZERO {
                    n<i32> = b.data
                    pos = pos + n
                } else {
                    tysize<i32> = ast.typesize(b.type)
                    src<i8*> = &b.data
                    t<i32> = 0
                    while t < tysize {
                        if pos < this.data.len {
                            dst<i8*> = this.data.ptr() + pos
                            *dst = src[t]
                        }
                        pos = pos + 1
                        t += 1
                    }
                }
                j += 1
            }
        }
        i += 1
    }
}

MachObjWriter::map_reloc(elf_type<i32>) u32, i32, i32 {
    if elf_type == R_X86_64_64 {
        return X86_64_RELOC_UNSIGNED, 0, 3
    }
    if elf_type == 42 || elf_type == R_X86_64_PLT32 {
        return X86_64_RELOC_BRANCH, 1, 2
    }
    if elf_type == R_X86_64_PC32 {
        return X86_64_RELOC_SIGNED, 1, 2
    }
    return X86_64_RELOC_SIGNED, 1, 2
}

MachObjWriter::sym_in_list(list<std.Array>, name<string.String>) i32 {
    i<i32> = 0
    while i < list.len() {
        s<ObjSym> = list.addr[i]
        if s.name.cmp(name) == string.Equal {
            return 1
        }
        i += 1
    }
    return 0
}

MachObjWriter::add_defined(sym<ast.Sym>, text_size<u64>) {
    if sym == null {
        return
    }
    if sym.name == null {
        return
    }
    if sym.name.empty() == string.True {
        return
    }
    o<ObjSym> = new ObjSym
    o.name = sym.name
    o.is_undef = 0
    o.is_ext = 0
    if sym.global || sym.externed {
        o.is_ext = 1
    }
    if sym.externed {
        o.n_type = N_EXT | N_UNDF
        o.n_sect = NO_SECT
        o.n_value = 0
        o.is_undef = 1
        o.is_ext = 1
        this.undef_syms.push(o)
        return
    }
    av<u64> = sym.addr
    if sym.segName.cmpstr(*".text") == string.Equal {
        o.n_sect = 1
        o.n_value = av
    } else if sym.segName.cmpstr(*".data") == string.Equal {
        o.n_sect = 2
        o.n_value = text_size + av
    } else {
        o.n_sect = 1
        o.n_value = av
    }
    o.n_type = N_SECT
    if o.is_ext {
        o.n_type = N_SECT | N_EXT
        this.ext_syms.push(o)
    } else {
        this.local_syms.push(o)
    }
}

MachObjWriter::collect_syms(ps<parser.Parser>, elfh<elf.ElfFile>, text_size<u64>) {
    ef<elf.ElfFile> = elfh
    iter<map.MapIter> = ps.symtable.symbols.iter()
    loop {
        if iter.next() == map.End {
            break
        }
        sym<ast.Sym> = iter.v()
        this.add_defined(sym, text_size)
    }
    i<i32> = 0
    while i < ef.relTab.len() {
        rel<elf.RelInfo> = ef.relTab.addr[i]
        if rel == null {
            i += 1
            continue
        }
        found<i32> = 0
        if this.sym_in_list(this.local_syms, rel.name) {
            found = 1
        }
        if found == 0 && this.sym_in_list(this.ext_syms, rel.name) {
            found = 1
        }
        if found == 0 && this.sym_in_list(this.undef_syms, rel.name) {
            found = 1
        }
        if found == 0 {
            s<ast.Sym> = ps.symtable.getSym(rel.name)
            if s != null {
                this.add_defined(s, text_size)
            } else {
                o<ObjSym> = new ObjSym
                o.name = rel.name
                o.n_type = N_EXT | N_UNDF
                o.n_sect = NO_SECT
                o.n_value = 0
                o.is_undef = 1
                o.is_ext = 1
                this.undef_syms.push(o)
            }
        }
        i += 1
    }
    i = 0
    while i < this.local_syms.len() {
        this.all_syms.push(this.local_syms.addr[i])
        i += 1
    }
    i = 0
    while i < this.ext_syms.len() {
        this.all_syms.push(this.ext_syms.addr[i])
        i += 1
    }
    i = 0
    while i < this.undef_syms.len() {
        this.all_syms.push(this.undef_syms.addr[i])
        i += 1
    }
    i = 0
    while i < this.all_syms.len() {
        s<ObjSym> = this.all_syms.addr[i]
        idx<i32> = i
        this.sym_index.insert(s.name, idx)
        i += 1
    }
}

MachObjWriter::collect_rels(elfh<elf.ElfFile>) {
    ef<elf.ElfFile> = elfh
    nrel<i32> = ef.relTab.len()
    i<i32> = 0
    while i < nrel {
        rp<u64> = ef.relTab.addr[i]
        if rp == 0 {
            i += 1
            continue
        }
        rel<elf.RelInfo> = rp
        if rel.name == null {
            i += 1
            continue
        }
        idx<i32> = -1
        j<i32> = 0
        while j < this.all_syms.len() {
            s<ObjSym> = this.all_syms.addr[j]
            if s.name != null && s.name.cmp(rel.name) == string.Equal {
                idx = j
                break
            }
            j += 1
        }
        if idx < 0 {
            fmt.printf("[tu/darwin] reloc symbol missing\n")
            os.die("darwin reloc")
        }
        pcrel<i32> = 0
        length<i32> = 2
        ty<u32> = 0
        ty, pcrel, length = this.map_reloc(rel.type)
        if rel.type == 42 {
            ty = X86_64_RELOC_BRANCH
            pcrel = 1
            length = 2
        }
        ro<RelOut> = new RelOut
        ro.address = rel.offset
        ro.symbolnum = i32_u32(idx)
        ro.pcrel = pcrel
        ro.length = length
        ro.ext = 1
        ro.ty = ty
        is_data<i32> = 0
        if rel.tarSeg != null {
            ts<i8*> = rel.tarSeg.str()
            if ts != null {
                c<i8> = ts[1]
                if c == 'd' {
                    is_data = 1
                }
            }
        }
        if is_data {
            this.data_rels.push(ro)
        } else {
            this.text_rels.push(ro)
        }
        i += 1
    }
}

MachObjWriter::wr(buf<u64>, n<i32>) {
    n64<u64> = n
    utils.fwrite(this.fd, buf, n64)
    this.wr_off = this.wr_off + n
}

MachObjWriter::pad_to(off<i32>) {
    loop {
        if this.wr_off >= off {
            break
        }
        z<i8> = 0
        one<u64> = 1
        utils.fwrite(this.fd, &z, one)
        this.wr_off = this.wr_off + 1
    }
}

MachObjWriter::emit(outpath) i32 {
    this.text.align_to(8, 0x90)
    text_size<i32> = this.text.len
    data_size<i32> = this.data.len
    ntr<i32> = this.text_rels.len()
    ndr<i32> = this.data_rels.len()
    nloc_i<i32> = this.local_syms.len()
    nexts_i<i32> = this.ext_syms.len()
    nund_i<i32> = this.undef_syms.len()
    nall<i32> = this.all_syms.len()

    mh_len<i32> = 32
    seg_len<i32> = 72
    sect_len<i32> = 80
    sym_len<i32> = 24
    dys_len<i32> = 80
    nl_len<i32> = 16
    nsects_i<i32> = 2
    seg_cmdsize_i<i32> = seg_len + nsects_i * sect_len
    sizeofcmds_i<i32> = seg_cmdsize_i + sym_len + dys_len
    header_and_cmds<i32> = mh_len + sizeofcmds_i
    text_off_i<i32> = header_and_cmds
    data_off_i<i32> = text_off_i + text_size
    content_end<i32> = data_off_i + data_size
    rel_base<i32> = content_end
    rem8<i32> = rel_base % 8
    if rem8 != 0 {
        rel_base = rel_base + (8 - rem8)
    }
    text_reloff_i<i32> = 0
    if ntr > 0 {
        text_reloff_i = rel_base
    }
    data_reloff_i<i32> = 0
    if ndr > 0 {
        if ntr == 0 {
            data_reloff_i = rel_base
        } else {
            data_reloff_i = rel_base + ntr * 8
        }
    }
    after_rel<i32> = rel_base + (ntr + ndr) * 8
    symoff_i<i32> = after_rel
    rem_sym<i32> = symoff_i % 8
    if rem_sym != 0 {
        symoff_i = symoff_i + (8 - rem_sym)
    }

    strtab<ByteBuf> = ByteBuf::create()
    strtab.push_u8(0)
    strx<std.Array> = std.NewArray()
    i<i32> = 0
    while i < nall {
        s<ObjSym> = this.all_syms.addr[i]
        off<i32> = strtab.len
        strx.push(off)
        sl<i32> = s.name.len()
        strtab.append(s.name.str(), sl)
        strtab.push_u8(0)
        i += 1
    }
    strtab.align_to(8, 0)
    stroff_i<i32> = symoff_i + nall * nl_len

    tsz64<u64> = i32_u64(text_size)
    dsz64<u64> = i32_u64(data_size)
    sizeofcmds<u32> = i32_u32(sizeofcmds_i)
    seg_cmdsize<u32> = i32_u32(seg_cmdsize_i)
    nsects<u32> = i32_u32(nsects_i)
    text_off<u32> = i32_u32(text_off_i)
    data_off<u32> = i32_u32(data_off_i)
    text_reloff<u32> = i32_u32(text_reloff_i)
    data_reloff<u32> = i32_u32(data_reloff_i)
    nreloc_t<u32> = i32_u32(ntr)
    nreloc_d<u32> = i32_u32(ndr)
    nallu<u32> = i32_u32(nall)
    nloc<u32> = i32_u32(nloc_i)
    nexts<u32> = i32_u32(nexts_i)
    nund<u32> = i32_u32(nund_i)
    symoff<u32> = i32_u32(symoff_i)
    stroff<u32> = i32_u32(stroff_i)
    stlen<u32> = i32_u32(strtab.len)

    fp<i32> = utils.fopen(outpath, "w+")
    if fp <= 0 {
        fmt.printf("[tu/darwin] cannot write %s\n", outpath)
        return 1
    }
    this.fd = fp
    this.wr_off = 0

    z32<u64> = i32_u64(mh_len)
    z72<u64> = i32_u64(seg_len)
    z80<u64> = i32_u64(sect_len)
    z24<u64> = i32_u64(sym_len)
    zdys<u64> = i32_u64(dys_len)
    znl<u64> = i32_u64(nl_len)

    mhb<u64> = macho_zero(mh_len)
    mh<MachHeader64> = mhb
    mh.magic = MH_MAGIC_64
    mh.cputype = CPU_TYPE_X86_64
    mh.cpusubtype = CPU_SUBTYPE_X86_64_ALL
    mh.filetype = MH_OBJECT
    mh.ncmds = 3
    mh.sizeofcmds = sizeofcmds
    mh.flags = 0
    this.wr(mhb, mh_len)

    segb<u64> = macho_zero(seg_len)
    seg<SegmentCommand64> = segb
    seg.cmd = LC_SEGMENT_64
    seg.cmdsize = seg_cmdsize
    seg.vmaddr = 0
    seg.vmsize = tsz64 + dsz64
    toff64<u64> = text_off
    seg.fileoff = toff64
    seg.filesize = tsz64 + dsz64
    seg.maxprot = 7
    seg.initprot = 7
    seg.nsects = nsects
    this.wr(segb, seg_len)

    stb<u64> = macho_zero(sect_len)
    sect_text<Section64> = stb
    poke_cstr(stb, 0, 95, 95, 116, 101, 120, 116, 0, 0, 0, 0)
    poke_cstr(stb, 16, 95, 95, 84, 69, 88, 84, 0, 0, 0, 0)
    sect_text.addr = 0
    sect_text.size = tsz64
    sect_text.offset = text_off
    sect_text.align = 0
    sect_text.reloff = text_reloff
    sect_text.nreloc = nreloc_t
    sect_text.flags = S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS
    this.wr(stb, sect_len)

    sdb<u64> = macho_zero(sect_len)
    sect_data<Section64> = sdb
    poke_cstr(sdb, 0, 95, 95, 100, 97, 116, 97, 0, 0, 0, 0)
    poke_cstr(sdb, 16, 95, 95, 68, 65, 84, 65, 0, 0, 0, 0)
    sect_data.addr = tsz64
    sect_data.size = dsz64
    sect_data.offset = data_off
    sect_data.align = 3
    sect_data.reloff = data_reloff
    sect_data.nreloc = nreloc_d
    sect_data.flags = S_REGULAR
    this.wr(sdb, sect_len)

    scb<u64> = macho_zero(sym_len)
    sc<SymtabCommand> = scb
    sc.cmd = LC_SYMTAB
    sc.cmdsize = i32_u32(sym_len)
    sc.symoff = symoff
    sc.nsyms = nallu
    sc.stroff = stroff
    sc.strsize = stlen
    this.wr(scb, sym_len)

    dcb<u64> = macho_zero(dys_len)
    dc<DysymtabCommand> = dcb
    dc.cmd = LC_DYSYMTAB
    dc.cmdsize = i32_u32(dys_len)
    dc.ilocalsym = 0
    dc.nlocalsym = nloc
    dc.iextdefsym = nloc
    dc.nextdefsym = nexts
    dc.iundefsym = nloc + nexts
    dc.nundefsym = nund
    this.wr(dcb, dys_len)

    this.pad_to(text_off_i)
    if this.text.len > 0 {
        this.wr(this.text.bits(), this.text.len)
    }
    this.pad_to(data_off_i)
    if this.data.len > 0 {
        this.wr(this.data.bits(), this.data.len)
    }

    if ntr > 0 {
        this.pad_to(text_reloff_i)
        i = 0
        while i < ntr {
            r<RelOut> = this.text_rels.addr[i]
            rbp<u64> = macho_zero(8)
            rb<i8*> = rbp
            reloc_pack(rb, r.address, r.symbolnum, r.pcrel, r.length, r.ext, r.ty)
            this.wr(rbp, 8)
            i += 1
        }
    }
    if ndr > 0 {
        this.pad_to(data_reloff_i)
        i = 0
        while i < ndr {
            r<RelOut> = this.data_rels.addr[i]
            rbp<u64> = macho_zero(8)
            rb<i8*> = rbp
            reloc_pack(rb, r.address, r.symbolnum, r.pcrel, r.length, r.ext, r.ty)
            this.wr(rbp, 8)
            i += 1
        }
    }

    this.pad_to(symoff_i)
    i = 0
    while i < nall {
        s<ObjSym> = this.all_syms.addr[i]
        nlb<u64> = macho_zero(nl_len)
        nl<Nlist64> = nlb
        sx<i32> = strx.addr[i]
        nl.n_strx = i32_u32(sx)
        nl.n_type = s.n_type
        nl.n_sect = s.n_sect
        nl.n_desc = 0
        nl.n_value = s.n_value
        this.wr(nlb, nl_len)
        i += 1
    }
    this.pad_to(stroff_i)
    if strtab.len > 0 {
        this.wr(strtab.bits(), strtab.len)
    }
    utils.fclose(this.fd)
    nrels<i32> = ntr + ndr
    fmt.printf("[tu/darwin] wrote Mach-O MH_OBJECT %s (text=%d data=%d syms=%d rels=%d)\n",
        outpath, int(text_size), int(data_size), int(nall), int(nrels))
    return 0
}

// Adapter: Parser + ElfFile relocs → MH_OBJECT. Returns 0 on success.
fn emit_object(ps<parser.Parser>, elfh<elf.ElfFile>, outpath) i32 {
    w<MachObjWriter> = MachObjWriter::create()
    w.collect_text(ps)
    w.collect_data(ps)
    w.text.align_to(8, 0x90)
    w.local_syms = std.NewArray()
    w.ext_syms = std.NewArray()
    w.undef_syms = std.NewArray()
    w.all_syms = std.NewArray()
    w.sym_index = map.map_new(mapstringhashkey.(u64), 0.(i8))
    padn2<i32> = w.text.len
    tsz2<u64> = padn2
    w.collect_syms(ps, elfh, tsz2)
    w.collect_rels(elfh)
    return w.emit(outpath)
}
