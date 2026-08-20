// Emit a COFF relocatable object from Parser instruct bytes + ElfFile relTab.
// Container mirrors the mother peff CoffWriter layout:
//   IMAGE_FILE_HEADER, section headers (.text/.data), raw contents,
//   per-section relocation tables, symbol table, string table.
// Undefined symbols stay IMAGE_SYM_UNDEFINED; the host PE linker builds the IAT.

use asmer.ast
use asmer.elf
use asmer.parser
use asmer.instruct
use asmer.utils
use std
use std.map
use string
use fmt

// One COFF symbol candidate (defined or undefined external).
mem CoffSym {
    string.String* name
    i32 value
    i32 section   // 1=.text 2=.data 0=undef
    i32 sym_type  // 0 or IMAGE_SYM_DTYPE_FUNCTION
    i32 storage
    i32 is_undef
}

// One COFF relocation before serialization.
mem CoffRelOut {
    i32 va
    i32 sym
    i32 ty
}

mem CoffObjWriter {
    ByteBuf* text
    ByteBuf* data
    std.Array* defined_syms
    std.Array* undef_syms
    std.Array* all_syms
    std.Array* text_rels
    std.Array* data_rels
}

const CoffObjWriter::create() CoffObjWriter {
    w<CoffObjWriter> = new CoffObjWriter
    w.text = ByteBuf::create()
    w.data = ByteBuf::create()
    w.defined_syms = std.NewArray()
    w.undef_syms = std.NewArray()
    w.all_syms = std.NewArray()
    w.text_rels = std.NewArray()
    w.data_rels = std.NewArray()
    return w
}

CoffObjWriter::collect_text(ps<parser.Parser>) {
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

CoffObjWriter::collect_data(ps<parser.Parser>) {
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
        if sym.isstr {
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

CoffObjWriter::sym_in_list(list<std.Array>, name<string.String>) i32 {
    i<i32> = 0
    while i < list.len() {
        s<CoffSym> = list.addr[i]
        if s.name.cmp(name) == string.Equal {
            return 1
        }
        i += 1
    }
    return 0
}

// Mirror of mother add_defined: externed -> undef, else .text/.data defined.
// Insertion-sort defined symbols by name so the COFF table matches
// mother CoffWriter (C++ std::map iteration is lexicographic).
CoffObjWriter::sort_defined_by_name() {
    n<i32> = this.defined_syms.len()
    i<i32> = 1
    while i < n {
        key<CoffSym> = this.defined_syms.addr[i]
        j<i32> = i
        loop {
            if j <= 0 {
                break
            }
            prev<CoffSym> = this.defined_syms.addr[j - 1]
            if prev.name.cmp(key.name) <= 0 {
                break
            }
            this.defined_syms.addr[j] = prev
            j -= 1
        }
        this.defined_syms.addr[j] = key
        i += 1
    }
}

CoffObjWriter::add_defined(sym<ast.Sym>) {
    if sym == null {
        return
    }
    if sym.name == null {
        return
    }
    if sym.name.empty() == string.True {
        return
    }
    if this.sym_in_list(this.defined_syms, sym.name) {
        return
    }
    if this.sym_in_list(this.undef_syms, sym.name) {
        return
    }
    o<CoffSym> = new CoffSym
    o.name = sym.name
    o.sym_type = 0
    if sym.externed {
        o.is_undef = 1
        o.section = IMAGE_SYM_UNDEFINED
        o.value = 0
        o.storage = IMAGE_SYM_CLASS_EXTERNAL
        ast.undef_vocab_hint(string.new(o.name.str()))
        this.undef_syms.push(o)
        return
    }
    o.is_undef = 0
    av<i32> = sym.addr
    if sym.segName.cmpstr(*".data") == string.Equal {
        o.section = 2
        o.value = av
        o.sym_type = 0
    } else {
        o.section = 1
        o.value = av
        o.sym_type = IMAGE_SYM_DTYPE_FUNCTION
    }
    if sym.global || sym.externed {
        o.storage = IMAGE_SYM_CLASS_EXTERNAL
    } else {
        o.storage = IMAGE_SYM_CLASS_STATIC
    }
    this.defined_syms.push(o)
}

CoffObjWriter::collect_syms(ps<parser.Parser>, elfh<elf.ElfFile>) {
    ef<elf.ElfFile> = elfh
    iter<map.MapIter> = ps.symtable.symbols.iter()
    loop {
        if iter.next() == map.End {
            break
        }
        sym<ast.Sym> = iter.v()
        this.add_defined(sym)
    }
    i<i32> = 0
    while i < ef.relTab.len() {
        rel<elf.RelInfo> = ef.relTab.addr[i]
        if rel == null {
            i += 1
            continue
        }
        found<i32> = 0
        if this.sym_in_list(this.defined_syms, rel.name) {
            found = 1
        }
        if found == 0 && this.sym_in_list(this.undef_syms, rel.name) {
            found = 1
        }
        if found == 0 {
            s<ast.Sym> = ps.symtable.getSym(rel.name)
            if s != null {
                this.add_defined(s)
            } else {
                o<CoffSym> = new CoffSym
                o.name = rel.name
                o.value = 0
                o.section = IMAGE_SYM_UNDEFINED
                o.sym_type = 0
                o.storage = IMAGE_SYM_CLASS_EXTERNAL
                o.is_undef = 1
                ast.undef_vocab_hint(string.new(o.name.str()))
                this.undef_syms.push(o)
            }
        }
        i += 1
    }
    this.sort_defined_by_name()
    i = 0
    while i < this.defined_syms.len() {
        this.all_syms.push(this.defined_syms.addr[i])
        i += 1
    }
    i = 0
    while i < this.undef_syms.len() {
        this.all_syms.push(this.undef_syms.addr[i])
        i += 1
    }
}

// ADDR64 for 64-bit absolute; everything else (PC32/PLT32/call 42) is REL32.
CoffObjWriter::map_reloc(elf_type<i32>) i32 {
    if elf_type == PEFF_R_X86_64_64 {
        return IMAGE_REL_AMD64_ADDR64
    }
    return IMAGE_REL_AMD64_REL32
}

CoffObjWriter::collect_rels(elfh<elf.ElfFile>) i32 {
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
            s<CoffSym> = this.all_syms.addr[j]
            if s.name != null && s.name.cmp(rel.name) == string.Equal {
                idx = j
                break
            }
            j += 1
        }
        if idx < 0 {
            fmt.printf("[tu/peff] reloc symbol missing\n")
            return 1
        }
        ro<CoffRelOut> = new CoffRelOut
        ro.va = rel.offset
        ro.sym = idx
        ro.ty = this.map_reloc(rel.type)
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
    return 0
}

// Serialize one 40-byte section header into ob.
CoffObjWriter::emit_section_header(ob<ByteBuf>, n0<i32>, n1<i32>, n2<i32>, n3<i32>, n4<i32>,
        raw_size<i32>, raw_off<i32>, rel_off<i32>, nrel<i32>, chars<u32>) {
    ob.push_u8(n0)
    ob.push_u8(n1)
    ob.push_u8(n2)
    ob.push_u8(n3)
    ob.push_u8(n4)
    ob.push_u8(0)
    ob.push_u8(0)
    ob.push_u8(0)
    ob.push_u32(0)                      // VirtualSize
    ob.push_u32(0)                      // VirtualAddress
    ob.push_u32(coff_i32_u32(raw_size)) // SizeOfRawData
    ob.push_u32(coff_i32_u32(raw_off))  // PointerToRawData
    ob.push_u32(coff_i32_u32(rel_off))  // PointerToRelocations
    ob.push_u32(0)                      // PointerToLinenumbers
    ob.push_u16(nrel)                   // NumberOfRelocations
    ob.push_u16(0)                      // NumberOfLinenumbers
    ob.push_u32(chars)                  // Characteristics
}

CoffObjWriter::emit(outpath) i32 {
    text_size<i32> = this.text.len
    data_size<i32> = this.data.len
    ntr<i32> = this.text_rels.len()
    ndr<i32> = this.data_rels.len()
    nall<i32> = this.all_syms.len()

    if ntr > 0xFFFF || ndr > 0xFFFF {
        fmt.printf("[tu/peff] too many relocs (need IMAGE_SCN_LNK_NRELOC_OVFL)\n")
        return 1
    }

    hdr_size<i32> = COFF_FILE_HEADER_LEN
    sectab_size<i32> = 2 * COFF_SECTION_HEADER_LEN
    text_off<i32> = coff_align4(hdr_size + sectab_size)
    data_off<i32> = coff_align4(text_off + text_size)
    after<i32> = coff_align4(data_off + data_size)
    text_rel_off<i32> = 0
    data_rel_off<i32> = 0
    if ntr > 0 {
        text_rel_off = after
        after = coff_align4(after + ntr * COFF_RELOC_LEN)
    }
    if ndr > 0 {
        data_rel_off = after
        after = coff_align4(after + ndr * COFF_RELOC_LEN)
    }
    sym_off<i32> = after

    ob<ByteBuf> = ByteBuf::create()

    // IMAGE_FILE_HEADER
    ob.push_u16(IMAGE_FILE_MACHINE_AMD64)
    ob.push_u16(2)                        // NumberOfSections
    ob.push_u32(0)                        // TimeDateStamp
    ob.push_u32(coff_i32_u32(sym_off))    // PointerToSymbolTable
    ob.push_u32(coff_i32_u32(nall))       // NumberOfSymbols
    ob.push_u16(0)                        // SizeOfOptionalHeader
    ob.push_u16(0)                        // Characteristics

    text_raw_off<i32> = 0
    if text_size > 0 {
        text_raw_off = text_off
    }
    data_raw_off<i32> = 0
    if data_size > 0 {
        data_raw_off = data_off
    }
    text_chars<u32> = IMAGE_SCN_CNT_CODE | IMAGE_SCN_MEM_EXECUTE | IMAGE_SCN_MEM_READ | IMAGE_SCN_ALIGN_1BYTES
    data_chars<u32> = IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ | IMAGE_SCN_MEM_WRITE | IMAGE_SCN_ALIGN_8BYTES
    // ".text" = 2e 74 65 78 74 ; ".data" = 2e 64 61 74 61
    this.emit_section_header(ob, 0x2e, 0x74, 0x65, 0x78, 0x74,
        text_size, text_raw_off, text_rel_off, ntr, text_chars)
    this.emit_section_header(ob, 0x2e, 0x64, 0x61, 0x74, 0x61,
        data_size, data_raw_off, data_rel_off, ndr, data_chars)

    if text_size > 0 {
        ob.pad_to(text_off)
        ob.append(this.text.ptr(), this.text.len)
    }
    if data_size > 0 {
        ob.pad_to(data_off)
        ob.append(this.data.ptr(), this.data.len)
    }

    i<i32> = 0
    if ntr > 0 {
        ob.pad_to(text_rel_off)
        i = 0
        while i < ntr {
            r<CoffRelOut> = this.text_rels.addr[i]
            ob.push_u32(coff_i32_u32(r.va))
            ob.push_u32(coff_i32_u32(r.sym))
            ob.push_u16(r.ty)
            i += 1
        }
    }
    if ndr > 0 {
        ob.pad_to(data_rel_off)
        i = 0
        while i < ndr {
            r<CoffRelOut> = this.data_rels.addr[i]
            ob.push_u32(coff_i32_u32(r.va))
            ob.push_u32(coff_i32_u32(r.sym))
            ob.push_u16(r.ty)
            i += 1
        }
    }

    // Symbol table + string pool (long names: Zeroes=0, Offset into pool+4).
    ob.pad_to(sym_off)
    pool<ByteBuf> = ByteBuf::create()
    i = 0
    while i < nall {
        s<CoffSym> = this.all_syms.addr[i]
        nlen<i32> = s.name.len()
        if nlen <= 8 {
            ob.append(s.name.str(), nlen)
            k<i32> = nlen
            while k < 8 {
                ob.push_u8(0)
                k += 1
            }
        } else {
            off32<i32> = 4 + pool.len
            pool.append(s.name.str(), nlen)
            pool.push_u8(0)
            ob.push_u32(0)
            ob.push_u32(coff_i32_u32(off32))
        }
        ob.push_u32(coff_i32_u32(s.value))
        ob.push_u16(s.section)
        ob.push_u16(s.sym_type)
        ob.push_u8(s.storage)
        ob.push_u8(0)                     // NumberOfAuxSymbols
        i += 1
    }
    strtab_size<i32> = 4 + pool.len
    ob.push_u32(coff_i32_u32(strtab_size))
    if pool.len > 0 {
        ob.append(pool.ptr(), pool.len)
    }

    fp<i32> = utils.fopen(outpath, "w+")
    if fp <= 0 {
        fmt.printf("[tu/peff] cannot write %s\n", outpath)
        return 1
    }
    utils.fwrite(fp, ob.bits(), ob.len)
    utils.fclose(fp)
    return 0
}

// Adapter: Parser + ElfFile relocs -> COFF object. Returns 0 on success.
fn emit_object(ps<parser.Parser>, elfh<elf.ElfFile>, outpath) i32 {
    w<CoffObjWriter> = CoffObjWriter::create()
    w.collect_text(ps)
    w.collect_data(ps)
    w.collect_syms(ps, elfh)
    rc<i32> = w.collect_rels(elfh)
    if rc != 0 {
        return rc
    }
    return w.emit(outpath)
}
