// Merge MH_OBJECT files into one MH_EXECUTE image.

use asmer.asm
use asmer.ast
use linker.utils
use std
use string
use fmt
use os

mem ImageSym {
    i32 name_off
    u8  n_type
    u8  n_sect
    u64 sect_off
}

mem NameRef {
    i32 off
}

mem MachImage {
    std.Array* objects
    ByteBuf*   text
    ByteBuf*   data
    NameTab*   names
    std.Array* defined
    OffMap*    def_by_off
    std.Array* slots
    std.Array* undef_names
}

unsafe fn path_basename(path) {
    n = std.len(path)
    i = n - 1
    while i >= 0 {
        if path[i] == '/' {
            break
        }
        i -= 1
    }
    return string.sub(path, i + 1)
}

unsafe fn stub_dir() {
    for (k, v : os.envs()) {
        arr = string.split(v, "=")
        if std.len(arr) >= 2 && arr[0] == "CO_DARWIN_LIB" && arr[1] != "" {
            return arr[1]
        }
    }
    // Embed/TU_STD: platform/darwin/stub_*.s from materialized stdroot.
    d = utils.stub_dir_for(1)
    if d != null && d != "" {
        probe = utils.path_join(d, "stub_entry.s")
        fp<i32> = utils.fopen(probe, "r")
        if fp > 0 {
            utils.fclose(fp)
            return d
        }
    }
    pref = utils.lib_root() + "/costub-darwin"
    fp<i32> = utils.fopen(pref + "/stub_entry.s", "r")
    if fp > 0 {
        utils.fclose(fp)
        return pref
    }
    alt = utils.lib_root() + "/codarwin"
    fp = utils.fopen(alt + "/stub_entry.s", "r")
    if fp > 0 {
        utils.fclose(fp)
        return alt
    }
    return pref
}

const MachImage::create() MachImage {
    m<MachImage> = new MachImage
    m.objects = std.NewArray()
    m.text = ByteBuf::create()
    m.data = ByteBuf::create()
    m.names = NameTab::create()
    m.defined = std.NewArray()
    m.def_by_off = OffMap::create()
    m.slots = std.NewArray()
    m.undef_names = std.NewArray()
    return m
}

MachImage::find_defined_off(off<i32>) ImageSym {
    idx<i32> = this.def_by_off.get(off)
    if idx < 0 {
        return null
    }
    return this.defined.addr[idx]
}

MachImage::find_defined_bytes(p<i8*>, n<i32>) ImageSym {
    i<i32> = 0
    while i < this.defined.len() {
        s<ImageSym> = this.defined.addr[i]
        if this.names.len_at(s.name_off) == n {
            if name_eq_bytes(this.names.ptr_at(s.name_off), p, n) != 0 {
                return s
            }
        }
        i += 1
    }
    return null
}

MachImage::find_defined_concat(pre<i8*>, plen<i32>, suf<i8*>, slen<i32>) ImageSym {
    want<i32> = plen + slen
    i<i32> = 0
    while i < this.defined.len() {
        s<ImageSym> = this.defined.addr[i]
        if this.names.len_at(s.name_off) != want {
            i += 1
            continue
        }
        p<i8*> = this.names.ptr_at(s.name_off)
        if name_eq_bytes(p, pre, plen) != 0 {
            if name_eq_bytes(p + plen, suf, slen) != 0 {
                return s
            }
        }
        i += 1
    }
    return null
}

MachImage::find_slot_off(off<i32>) ImportSlot {
    i<i32> = 0
    while i < this.slots.len() {
        sl<ImportSlot> = this.slots.addr[i]
        if sl.name_off == off {
            return sl
        }
        i += 1
    }
    return null
}

MachImage::sym_va(s<ImageSym>, text_sect_va<u64>, data_sect_va<u64>) u64 {
    if s.n_sect == 1 {
        return text_sect_va + s.sect_off
    }
    if s.n_sect == 2 {
        return data_sect_va + s.sect_off
    }
    return s.sect_off
}

MachImage::lookup_va_off(off<i32>, text_sect_va<u64>, data_sect_va<u64>) u64, i32 {
    s<ImageSym> = this.find_defined_off(off)
    if s != null {
        return this.sym_va(s, text_sect_va, data_sect_va), 0
    }
    sl<ImportSlot> = this.find_slot_off(off)
    if sl != null {
        return text_sect_va + u32_u64(sl.stub_off), 0
    }
    return 0, 1
}

MachImage::add_object(path) i32 {
    o<MachObject>, err<i32> = MachObject::load(path)
    if err != 0 {
        return 1
    }
    this.objects.push(o)
    return 0
}

MachImage::merge() {
    fi<i32> = 0
    while fi < this.objects.len() {
        f<MachObject> = this.objects.addr[fi]
        tl<i32> = this.text.len
        text_base<u64> = i32_u64(tl)
        this.text.append(f.text.ptr(), f.text.len)
        this.data.align_to(8, 0)
        dl<i32> = this.data.len
        data_base<u64> = i32_u64(dl)
        this.data.append(f.data.ptr(), f.data.len)

        ri<i32> = 0
        while ri < f.text_rels.len() {
            r<ObjRel> = f.text_rels.addr[ri]
            r.address = r.address + u64_i32(text_base)
            r.name_off = this.names.intern_off(f.names, r.name_off)
            ri += 1
        }
        ri = 0
        while ri < f.data_rels.len() {
            r<ObjRel> = f.data_rels.addr[ri]
            r.address = r.address + u64_i32(data_base)
            r.name_off = this.names.intern_off(f.names, r.name_off)
            ri += 1
        }

        si<i32> = 0
        while si < f.syms.len() {
            s<ObjSym> = f.syms.addr[si]
            ioff<i32> = this.names.intern_off(f.names, s.name_off)
            is_undef<i32> = 0
            if (s.n_type & N_TYPE) == N_UNDF && s.n_sect == 0 {
                is_undef = 1
            }
            if is_undef {
                nr<NameRef> = new NameRef
                nr.off = ioff
                this.undef_names.push(nr)
                si += 1
                continue
            }
            if this.find_defined_off(ioff) != null {
                si += 1
                continue
            }
            ps<ImageSym> = new ImageSym
            ps.name_off = ioff
            ps.n_type = s.n_type
            ps.n_sect = s.n_sect
            if s.n_sect == 1 {
                ps.sect_off = text_base + s.sect_off
            } else if s.n_sect == 2 {
                ps.sect_off = data_base + s.sect_off
            } else {
                ps.sect_off = s.sect_off
            }
            idx<i32> = this.defined.len()
            this.defined.push(ps)
            this.def_by_off.put(ioff, idx)
            si += 1
        }
        fi += 1
    }
}

MachImage::resolve_imports() i32 {
    i<i32> = 0
    while i < this.undef_names.len() {
        nr<NameRef> = this.undef_names.addr[i]
        off<i32> = nr.off
        if this.find_defined_off(off) != null {
            i += 1
            continue
        }
        if this.find_slot_off(off) != null {
            i += 1
            continue
        }
        if libsystem_allows(this.names, off) == 0 {
            unsafe {
                nm = string.new(this.names.ptr_at(off))
                fmt.printf("[tu/darwin] undefined symbol: ")
                fmt.printf(nm)
                fmt.printf("\n")
                ast.undef_vocab_hint(nm)
            }
            return 1
        }
        this.data.align_to(8, 0)
        slot<ImportSlot> = new ImportSlot
        slot.name_off = off
        slot.got_off = i32_u32(this.data.len)
        z<i32> = 0
        while z < 8 {
            this.data.push_u8(0)
            z += 1
        }
        slot.stub_off = emit_import_stub(this.text, slot.got_off)
        this.slots.push(slot)
        i += 1
    }
    main_off<i32> = this.names.intern_cstr(*"_main")
    if this.find_defined_off(main_off) == null {
        fmt.printf("[tu/darwin] missing _main (stub_entry not linked?)\n")
        return 1
    }
    return 0
}

MachImage::apply_relocs(sec<ByteBuf>, sec_va<u64>, rels<std.Array>, text_sect_va<u64>, data_sect_va<u64>) i32 {
    i<i32> = 0
    while i < rels.len() {
        r<ObjRel> = rels.addr[i]
        if r.address < 0 || r.address >= sec.len {
            fmt.printf("[tu/darwin] reloc address OOB\n")
            return 1
        }
        tva<u64> = 0
        verr<i32> = 0
        tva, verr = this.lookup_va_off(r.name_off, text_sect_va, data_sect_va)
        if verr != 0 {
            fmt.printf("[tu/darwin] reloc undef %s\n", this.names.ptr_at(r.name_off))
            return 1
        }
        loc_va<u64> = sec_va + i32_u64(r.address)
        if r.ty == X86_64_RELOC_BRANCH || r.ty == X86_64_RELOC_SIGNED {
            loc4<u64> = loc_va + 4
            disp<i64> = u64_i64(tva) - u64_i64(loc4)
            sec.set_u32_at(r.address, i64_u32(disp))
        } else if r.ty == X86_64_RELOC_UNSIGNED {
            if r.length == 3 {
                sec.set_u64_at(r.address, tva)
            } else if r.length == 2 {
                sec.set_u32_at(r.address, u64_u32(tva))
            } else {
                fmt.printf("[tu/darwin] unsupported UNSIGNED length %d\n", int(r.length))
                return 1
            }
        } else {
            rty<i32> = r.ty
            fmt.printf("[tu/darwin] unsupported reloc type %d for %s\n", int(rty), this.names.ptr_at(r.name_off))
            return 1
        }
        i += 1
    }
    return 0
}

MachImage::wr_fd(fd<i64>, buf<u64>, n<i32>, wr_off<i32>) i32 {
    n64<u64> = n
    utils.fwrite(fd, buf, n64)
    return wr_off + n
}

MachImage::pad_fd(fd<i64>, off<i32>, wr_off<i32>) i32 {
    one<u64> = 1
    cur<i32> = wr_off
    loop {
        if cur >= off {
            break
        }
        z<i8> = 0
        utils.fwrite(fd, &z, one)
        cur = cur + 1
    }
    return cur
}

MachImage::write_path_cmd(fd<i64>, lcmd<u32>, cmdsize<u32>, name_off<u32>, path<i8*>, fixed<u64>, fixed_len<i32>, wr_off<i32>) i32 {
    nalloc<i32> = cmdsize
    bb<u64> = macho_zero(nalloc)
    buf<i8*> = bb
    csz<u64> = cmdsize
    flen<u64> = fixed_len
    four<u64> = 4
    std.memcpy(buf, fixed, flen)
    std.memcpy(buf, &lcmd, four)
    std.memcpy(buf + 4, &cmdsize, four)
    plen<i32> = 0
    loop {
        if path[plen] == 0 {
            break
        }
        plen += 1
    }
    plen += 1
    noff<i32> = name_off
    plen64<u64> = plen
    std.memcpy(buf + noff, path, plen64)
    utils.fwrite(fd, buf, csz)
    add<i32> = cmdsize
    return wr_off + add
}

MachImage::link(outfile) i32 {
    if this.objects.len() <= 0 {
        fmt.printf("[tu/darwin] no object files\n")
        return 1
    }
    this.merge()
    if this.pcln_expand() != 0 {
        return 1
    }
    if this.resolve_imports() != 0 {
        return 1
    }

    pagezero_size<u64> = text_va_base()
    text_va<u64> = text_va_base()
    page_size<u32> = i32_u32(PAGE_SIZE)
    dyld_path<i8*> = null
    libsys_path<i8*> = null
    dylinker_sz<u32> = 0
    dylib_sz<u32> = 0
    unsafe {
        dyld_dyn = "/usr/lib/dyld"
        libsys_dyn = "/usr/lib/libSystem.B.dylib"
        dyld_path = *dyld_dyn
        libsys_path = *libsys_dyn
        dylinker_sz = path_cmdsize(i32_u32(DYLINKER_COMMAND_FIXED), dyld_path)
        dylib_sz = path_cmdsize(i32_u32(DYLIB_COMMAND_FIXED), libsys_path)
    }
    has_imports<i32> = 0
    if this.slots.len() > 0 {
        has_imports = 1
    }
    ncmds<u32> = 11
    if has_imports {
        ncmds = 12
    }
    sizeofcmds_i<i32> = SEGMENT_COMMAND64_LEN
        + SEGMENT_COMMAND64_LEN + SECTION64_LEN
        + SEGMENT_COMMAND64_LEN + SECTION64_LEN
        + SEGMENT_COMMAND64_LEN
        + SYMTAB_COMMAND_LEN + DYSYMTAB_COMMAND_LEN
        + u32_i32(dylinker_sz) + UUID_COMMAND_LEN
        + BUILD_VERSION_COMMAND_LEN
        + ENTRY_POINT_COMMAND_LEN + u32_i32(dylib_sz)
    if has_imports {
        sizeofcmds_i = sizeofcmds_i + DYLD_INFO_COMMAND_LEN
    }
    sizeofcmds<u32> = i32_u32(sizeofcmds_i)
    header_size<u32> = i32_u32(MACH_HEADER64_LEN + sizeofcmds_i)
    text_file_off<u32> = header_size

    this.text.align_to(16, 0x90)
    this.data.align_to(8, 0)
    text_content_sz<u32> = i32_u32(this.text.len)
    data_content_sz<u32> = i32_u32(this.data.len)
    text_seg_filesize<u32> = align_up_u32(header_size + text_content_sz, page_size)
    data_file_off<u32> = text_seg_filesize
    data_seg_filesize<u32> = align_up_u32(data_content_sz, page_size)
    if data_content_sz == 0 {
        data_seg_filesize = page_size
    }
    text_sect_va<u64> = text_va + u32_u64(header_size)
    data_sect_va<u64> = text_va + u32_u64(data_file_off)

    si<i32> = 0
    while si < this.slots.len() {
        sl<ImportSlot> = this.slots.addr[si]
        stub_va<u64> = text_sect_va + u32_u64(sl.stub_off)
        got_va<u64> = data_sect_va + u32_u64(sl.got_off)
        patch_stub(this.text, sl.stub_off, stub_va, got_va)
        si += 1
    }
    bind_opcodes<ByteBuf> = ByteBuf::create()
    if has_imports {
        bind_opcodes = build_bind(this.slots, this.names)
        bind_opcodes.align_to(8, 0)
    }

    linkedit_off<u32> = align_up_u32(data_file_off + data_seg_filesize, page_size)
    bind_off<u32> = 0
    bind_size<u32> = 0
    symoff<u32> = linkedit_off
    if has_imports {
        bind_off = linkedit_off
        bind_size = i32_u32(bind_opcodes.len)
        symoff = align_up_u32(bind_off + bind_size, 8)
    }

    ndef_i<i32> = this.defined.len()
    nimp_i<i32> = this.slots.len()
    n_extdef<u32> = i32_u32(ndef_i)
    n_undef<u32> = i32_u32(nimp_i)
    nsyms<u32> = n_extdef + n_undef
    main_off<i32> = this.names.intern_cstr(*"_main")
    this.names.align_strtab()
    stroff<u32> = symoff + nsyms * i32_u32(NLIST64_LEN)
    linkedit_sz<u32> = align_up_u32((stroff - linkedit_off) + i32_u32(this.names.strsize()), page_size)

    main_va<u64> = 0
    merr<i32> = 0
    main_va, merr = this.lookup_va_off(main_off, text_sect_va, data_sect_va)
    if merr != 0 {
        fmt.printf("[tu/darwin] missing _main VA\n")
        return 1
    }
    entryoff<u64> = main_va - text_va
    fi<i32> = 0
    while fi < this.objects.len() {
        f<MachObject> = this.objects.addr[fi]
        if this.apply_relocs(this.text, text_sect_va, f.text_rels, text_sect_va, data_sect_va) != 0 {
            return 1
        }
        if this.apply_relocs(this.data, data_sect_va, f.data_rels, text_sect_va, data_sect_va) != 0 {
            return 1
        }
        fi += 1
    }
    if this.pcln_fill(text_sect_va, data_sect_va) != 0 {
        return 1
    }

    fp<i32> = utils.fopen(outfile, "w+")
    if fp <= 0 {
        fmt.printf("[tu/darwin] cannot write %s\n", outfile)
        return 1
    }
    wr_off<i32> = 0

    mh_len<i32> = 32
    seg_len<i32> = 72
    sect_len<i32> = 80
    sym_len<i32> = 24
    dys_len<i32> = 80
    nl_len<i32> = 16
    dyld_len<i32> = 48
    uuid_len<i32> = 24
    bv_len<i32> = 24
    ep_len<i32> = 24
    dyl_fixed<i32> = 12
    dylib_fixed<i32> = 24
    z32<u64> = i32_u64(mh_len)
    z72<u64> = i32_u64(seg_len)
    z80<u64> = i32_u64(sect_len)
    z24<u64> = i32_u64(sym_len)
    zdys<u64> = i32_u64(dys_len)
    znl<u64> = i32_u64(nl_len)
    zdi<u64> = i32_u64(dyld_len)
    zuuid<u64> = i32_u64(uuid_len)
    zbv<u64> = i32_u64(bv_len)
    zep<u64> = i32_u64(ep_len)
    zdyl<u64> = i32_u64(dyl_fixed)
    zdylib<u64> = i32_u64(dylib_fixed)

    mhb<u64> = macho_zero(mh_len)
    mh<MachHeader64> = mhb
    mh.magic = MH_MAGIC_64
    mh.cputype = CPU_TYPE_X86_64
    mh.cpusubtype = CPU_SUBTYPE_X86_64_ALL
    mh.filetype = MH_EXECUTE
    mh.ncmds = ncmds
    mh.sizeofcmds = sizeofcmds
    mh.flags = MH_NOUNDEFS | MH_DYLDLINK | MH_TWOLEVEL
    wr_off = this.wr_fd(fp, mhb, mh_len, wr_off)

    pzb<u64> = macho_zero(seg_len)
    pagezero<SegmentCommand64> = pzb
    pagezero.cmd = LC_SEGMENT_64
    pagezero.cmdsize = i32_u32(seg_len)
    poke_cstr(pzb, 8, 95, 95, 80, 65, 71, 69, 90, 69, 82, 79)
    pagezero.vmaddr = 0
    pagezero.vmsize = pagezero_size
    pagezero.fileoff = 0
    pagezero.filesize = 0
    pagezero.maxprot = 0
    pagezero.initprot = 0
    pagezero.nsects = 0
    wr_off = this.wr_fd(fp, pzb, seg_len, wr_off)

    tsb<u64> = macho_zero(seg_len)
    textseg<SegmentCommand64> = tsb
    textseg.cmd = LC_SEGMENT_64
    textseg.cmdsize = i32_u32(seg_len + sect_len)
    poke_cstr(tsb, 8, 95, 95, 84, 69, 88, 84, 0, 0, 0, 0)
    textseg.vmaddr = text_va
    textseg.vmsize = u32_u64(text_seg_filesize)
    textseg.fileoff = 0
    textseg.filesize = u32_u64(text_seg_filesize)
    textseg.maxprot = 7
    textseg.initprot = 5
    textseg.nsects = 1
    wr_off = this.wr_fd(fp, tsb, seg_len, wr_off)

    txb<u64> = macho_zero(sect_len)
    textsec<Section64> = txb
    poke_cstr(txb, 0, 95, 95, 116, 101, 120, 116, 0, 0, 0, 0)
    poke_cstr(txb, 16, 95, 95, 84, 69, 88, 84, 0, 0, 0, 0)
    textsec.addr = text_sect_va
    textsec.size = u32_u64(text_content_sz)
    textsec.offset = text_file_off
    textsec.align = 4
    textsec.flags = S_ATTR_PURE_INSTRUCTIONS | S_ATTR_SOME_INSTRUCTIONS
    wr_off = this.wr_fd(fp, txb, sect_len, wr_off)

    dsb<u64> = macho_zero(seg_len)
    dataseg<SegmentCommand64> = dsb
    dataseg.cmd = LC_SEGMENT_64
    dataseg.cmdsize = i32_u32(seg_len + sect_len)
    poke_cstr(dsb, 8, 95, 95, 68, 65, 84, 65, 0, 0, 0, 0)
    dataseg.vmaddr = data_sect_va
    dataseg.vmsize = u32_u64(data_seg_filesize)
    dataseg.fileoff = u32_u64(data_file_off)
    dataseg.filesize = u32_u64(data_seg_filesize)
    dataseg.maxprot = 7
    dataseg.initprot = 3
    dataseg.nsects = 1
    wr_off = this.wr_fd(fp, dsb, seg_len, wr_off)

    dxb<u64> = macho_zero(sect_len)
    datasec<Section64> = dxb
    poke_cstr(dxb, 0, 95, 95, 100, 97, 116, 97, 0, 0, 0, 0)
    poke_cstr(dxb, 16, 95, 95, 68, 65, 84, 65, 0, 0, 0, 0)
    datasec.addr = data_sect_va
    datasec.size = u32_u64(data_content_sz)
    datasec.offset = data_file_off
    datasec.align = 3
    datasec.flags = S_REGULAR
    wr_off = this.wr_fd(fp, dxb, sect_len, wr_off)

    leb<u64> = macho_zero(seg_len)
    linkedit<SegmentCommand64> = leb
    linkedit.cmd = LC_SEGMENT_64
    linkedit.cmdsize = i32_u32(seg_len)
    poke_cstr(leb, 8, 95, 95, 76, 73, 78, 75, 69, 68, 73, 84)
    linkedit.vmaddr = data_sect_va + u32_u64(data_seg_filesize)
    linkedit.vmsize = u32_u64(linkedit_sz)
    linkedit.fileoff = u32_u64(linkedit_off)
    linkedit.filesize = u32_u64(linkedit_sz)
    linkedit.maxprot = 7
    linkedit.initprot = 1
    wr_off = this.wr_fd(fp, leb, seg_len, wr_off)

    if has_imports {
        dib<u64> = macho_zero(dyld_len)
        di<DyldInfoCommand> = dib
        di.cmd = LC_DYLD_INFO_ONLY
        di.cmdsize = i32_u32(dyld_len)
        di.bind_off = bind_off
        di.bind_size = bind_size
        wr_off = this.wr_fd(fp, dib, dyld_len, wr_off)
    }

    scb<u64> = macho_zero(sym_len)
    sc<SymtabCommand> = scb
    sc.cmd = LC_SYMTAB
    sc.cmdsize = i32_u32(sym_len)
    sc.symoff = symoff
    sc.nsyms = nsyms
    sc.stroff = stroff
    sc.strsize = i32_u32(this.names.strsize())
    wr_off = this.wr_fd(fp, scb, sym_len, wr_off)

    dcb<u64> = macho_zero(dys_len)
    dc<DysymtabCommand> = dcb
    dc.cmd = LC_DYSYMTAB
    dc.cmdsize = i32_u32(dys_len)
    dc.ilocalsym = 0
    dc.nlocalsym = 0
    dc.iextdefsym = 0
    dc.nextdefsym = n_extdef
    dc.iundefsym = n_extdef
    dc.nundefsym = n_undef
    wr_off = this.wr_fd(fp, dcb, dys_len, wr_off)

    dlcb<u64> = macho_zero(dyl_fixed)
    dlc<DylinkerCommand> = dlcb
    dlc.cmd = LC_LOAD_DYLINKER
    dlc.cmdsize = dylinker_sz
    dlc.name_offset = 12
    wr_off = this.write_path_cmd(fp, dlc.cmd, dlc.cmdsize, dlc.name_offset, dyld_path, dlcb, dyl_fixed, wr_off)

    uuidb<u64> = macho_zero(uuid_len)
    uuidc<UuidCommand> = uuidb
    uuidc.cmd = LC_UUID
    uuidc.cmdsize = i32_u32(uuid_len)
    wr_off = this.wr_fd(fp, uuidb, uuid_len, wr_off)

    bvb<u64> = macho_zero(bv_len)
    bvc<BuildVersionCommand> = bvb
    bvc.cmd = LC_BUILD_VERSION
    bvc.cmdsize = i32_u32(bv_len)
    bvc.platform = PLATFORM_MACOS
    minos_maj<u32> = 13
    bvc.minos = minos_maj << 16
    bvc.sdk = 0
    bvc.ntools = 0
    wr_off = this.wr_fd(fp, bvb, bv_len, wr_off)

    epb<u64> = macho_zero(ep_len)
    ep<EntryPointCommand> = epb
    ep.cmd = LC_MAIN
    ep.cmdsize = i32_u32(ep_len)
    ep.entryoff = entryoff
    ep.stacksize = 0
    wr_off = this.wr_fd(fp, epb, ep_len, wr_off)

    dycb<u64> = macho_zero(dylib_fixed)
    dyc<DylibCommand> = dycb
    dyc.cmd = LC_LOAD_DYLIB
    dyc.cmdsize = dylib_sz
    dyc.name_offset = 24
    dyc.timestamp = 2
    dyc.current_version = 0
    dyc.compatibility_version = 0
    wr_off = this.write_path_cmd(fp, dyc.cmd, dyc.cmdsize, dyc.name_offset, libsys_path, dycb, dylib_fixed, wr_off)

    hs_i<i32> = header_size
    if wr_off != hs_i {
        fmt.printf("[tu/darwin] cmd size mismatch got=%d want=%d\n", int(wr_off), int(hs_i))
        utils.fclose(fp)
        return 1
    }

    wr_off = this.pad_fd(fp, u32_i32(text_file_off), wr_off)
    if this.text.len > 0 {
        wr_off = this.wr_fd(fp, this.text.bits(), this.text.len, wr_off)
    }
    wr_off = this.pad_fd(fp, u32_i32(data_file_off), wr_off)
    if this.data.len > 0 {
        wr_off = this.wr_fd(fp, this.data.bits(), this.data.len, wr_off)
    }
    wr_off = this.pad_fd(fp, u32_i32(linkedit_off), wr_off)
    if has_imports {
        wr_off = this.pad_fd(fp, u32_i32(bind_off), wr_off)
        wr_off = this.wr_fd(fp, bind_opcodes.bits(), bind_opcodes.len, wr_off)
    }
    wr_off = this.pad_fd(fp, u32_i32(symoff), wr_off)
    i<i32> = 0
    while i < this.defined.len() {
        s<ImageSym> = this.defined.addr[i]
        nlb<u64> = macho_zero(nl_len)
        nl<Nlist64> = nlb
        nl.n_strx = i32_u32(s.name_off)
        nl.n_type = N_SECT | N_EXT
        nl.n_sect = s.n_sect
        nl.n_value = this.sym_va(s, text_sect_va, data_sect_va)
        wr_off = this.wr_fd(fp, nlb, nl_len, wr_off)
        i += 1
    }
    i = 0
    while i < this.slots.len() {
        sl2<ImportSlot> = this.slots.addr[i]
        nlb<u64> = macho_zero(nl_len)
        nl<Nlist64> = nlb
        nl.n_strx = i32_u32(sl2.name_off)
        nl.n_type = N_EXT | N_UNDF
        nl.n_sect = NO_SECT
        libord<u16> = 1
        nl.n_desc = (libord << 8) | REFERENCE_FLAG_UNDEFINED_NON_LAZY
        nl.n_value = 0
        wr_off = this.wr_fd(fp, nlb, nl_len, wr_off)
        i += 1
    }
    wr_off = this.pad_fd(fp, u32_i32(stroff), wr_off)
    if this.names.strsize() > 0 {
        wr_off = this.wr_fd(fp, this.names.bits(), this.names.strsize(), wr_off)
    }
    le_end<i32> = u32_i32(linkedit_off + linkedit_sz)
    wr_off = this.pad_fd(fp, le_end, wr_off)
    utils.fclose(fp)
    os.shell("chmod 755 '" + outfile + "'")
    eoff_i<i32> = u64_i32(entryoff)
    fmt.printf("[tu/darwin] wrote MH_EXECUTE %s (entryoff=%d imports=%d)\n",
        outfile, int(eoff_i), int(nimp_i))
    return 0
}

// Assemble stub .s with asmer.darwin into out_o next to outfile.
unsafe fn ensure_stub_obj(src_s, out_o) i32 {
    sdir = utils.path_dirname(out_o)
    stem = path_basename(out_o)
    s_name = string.sub(stem, 0)
    // stem is *.o → corresponding .s name
    n = std.len(stem)
    if n > 2 && stem[n - 2] == '.' {
        s_name = string.sub(stem, 0)
        // drop last 2 chars: use concat rebuild
        base = ""
        j = 0
        while j < n - 2 {
            base += stem[j]
            j += 1
        }
        s_name = base + ".s"
    }
    s_path = utils.path_join(sdir, s_name)
    os.shell("cp '" + src_s + "' '" + s_path + "'")
    asm.requested_target = "darwin"
    eng<asm.Asmer> = new asm.Asmer(s_path)
    eng.execute()
    return 0
}

unsafe fn objs_have_basename(files, name) {
    for f : files {
        if path_basename(f) == name {
            return true
        }
    }
    return false
}

// Collect user objects + nostd stubs, then link.
unsafe fn link_objects(files, outfile) {
    all = []
    full_rt = objs_have_basename(files, "asm_amd64.o")
    for f : files {
        b = path_basename(f)
        if b == "codarwin_stub_entry.o" || b == "codarwin_stub_runtime.o" {
            continue
        }
        all[] = f
    }
    if !full_rt {
        sdir = stub_dir()
        out_dir = utils.path_dirname(outfile)
        entry_s = sdir + "/stub_entry.s"
        entry_o = utils.path_join(out_dir, "codarwin_stub_entry.o")
        if ensure_stub_obj(entry_s, entry_o) != 0 {
            return 1
        }
        all[] = entry_o
        runtime_s = sdir + "/stub_runtime.s"
        fp<i32> = utils.fopen(runtime_s, "r")
        if fp > 0 {
            utils.fclose(fp)
            runtime_o = utils.path_join(out_dir, "codarwin_stub_runtime.o")
            ensure_stub_obj(runtime_s, runtime_o)
            all[] = runtime_o
        }
    }
    img<MachImage> = MachImage::create()
    for f : all {
        if img.add_object(f) != 0 {
            return 1
        }
    }
    rc<i32> = img.link(outfile)
    if rc != 0 {
        return 1
    }
    return 0
}
