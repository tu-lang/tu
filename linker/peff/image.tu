// Merge AMD64 COFF objects into one PE executable. No host link.exe.

use asmer.asm
use asmer.ast
use linker.utils
use std
use string
use fmt
use os

mem ImageSym {
    i32 name_off
    i32 n_sect
    u64 sect_off
}

mem NameRef {
    i32 off
}

mem PeImage {
    std.Array* objects
    ByteBuf*   text
    ByteBuf*   data
    ByteBuf*   rdata
    NameTab*   names
    std.Array* defined
    OffMap*    def_by_off
    std.Array* slots
    std.Array* undef_names
    // Noscan layout blob (u64 + u32s). Must not live as GC-scanned fields —
    // ImageBase / file offsets look like pointers and get smashed on alloc.
    ByteBuf*   layout
}

fn pe_image_base() u64 {
    one<u64> = 1
    hi<u64> = one << 32
    lo<u64> = 0x40000000
    return hi + lo
}

const PeImage::create() PeImage {
    m<PeImage> = new PeImage
    m.objects = std.NewArray()
    m.text = ByteBuf::create()
    m.data = ByteBuf::create()
    m.rdata = ByteBuf::create()
    m.names = NameTab::create()
    m.defined = std.NewArray()
    m.def_by_off = OffMap::create()
    m.slots = std.NewArray()
    m.undef_names = std.NewArray()
    m.layout = ByteBuf::zeros(128)
    return m
}

PeImage::find_defined_off(off<i32>) ImageSym {
    idx<i32> = this.def_by_off.get(off)
    if idx < 0 {
        return null
    }
    return this.defined.addr[idx]
}

PeImage::find_defined_bytes(p<i8*>, n<i32>) ImageSym {
    i<i32> = 0
    while i < this.defined.used {
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

PeImage::find_defined_concat(pre<i8*>, plen<i32>, suf<i8*>, slen<i32>) ImageSym {
    want<i32> = plen + slen
    i<i32> = 0
    while i < this.defined.used {
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

PeImage::find_slot_off(off<i32>) ImportSlot {
    i<i32> = 0
    while i < this.slots.used {
        sl<ImportSlot> = this.slots.addr[i]
        if sl.name_off == off {
            return sl
        }
        i += 1
    }
    return null
}

PeImage::sym_va(s<ImageSym>, text_va<u64>, data_va<u64>) u64 {
    if s.n_sect == 1 {
        return text_va + s.sect_off
    }
    if s.n_sect == 2 {
        return data_va + s.sect_off
    }
    return s.sect_off
}

PeImage::lookup_va_off(off<i32>, text_va<u64>, data_va<u64>) u64, i32 {
    s<ImageSym> = this.find_defined_off(off)
    if s != null {
        return this.sym_va(s, text_va, data_va), 0
    }
    sl<ImportSlot> = this.find_slot_off(off)
    if sl != null {
        return text_va + u32_u64(sl.stub_off), 0
    }
    return 0, 1
}

PeImage::add_object(path) i32 {
    o<CoffObject>, err<i32> = CoffObject::load(path)
    if err != 0 {
        return 1
    }
    this.objects.push(o)
    return 0
}

PeImage::merge() {
    fi<i32> = 0
    while fi < this.objects.used {
        f<CoffObject> = this.objects.addr[fi]
        this.text.align_to(16, 0x90)
        tl<i32> = this.text.len
        text_base<u64> = i32_u64(tl)
        this.text.append(f.text.ptr(), f.text.len)
        this.data.align_to(8, 0)
        dl<i32> = this.data.len
        data_base<u64> = i32_u64(dl)
        this.data.append(f.data.ptr(), f.data.len)

        ri<i32> = 0
        while ri < f.text_rels.used {
            r<ObjRel> = f.text_rels.addr[ri]
            r.address = r.address + u64_i32(text_base)
            r.name_off = this.names.intern_off(f.names, r.name_off)
            ri += 1
        }
        ri = 0
        while ri < f.data_rels.used {
            r<ObjRel> = f.data_rels.addr[ri]
            r.address = r.address + u64_i32(data_base)
            r.name_off = this.names.intern_off(f.names, r.name_off)
            ri += 1
        }

        si<i32> = 0
        while si < f.syms.used {
            s<ObjSym> = f.syms.addr[si]
            ioff<i32> = this.names.intern_off(f.names, s.name_off)
            if s.n_sect == 0 {
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
            ps.n_sect = s.n_sect
            if s.n_sect == 1 {
                ps.sect_off = text_base + i32_u64(s.value)
            } else if s.n_sect == 2 {
                ps.sect_off = data_base + i32_u64(s.value)
            } else {
                ps.sect_off = i32_u64(s.value)
            }
            idx<i32> = this.defined.used
            this.defined.push(ps)
            this.def_by_off.put(ioff, idx)
            si += 1
        }
        fi += 1
    }
}

PeImage::resolve_imports() i32 {
    i<i32> = 0
    while i < this.undef_names.used {
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
        dll<i32> = win_dll_id(this.names, off)
        if dll < 0 {
            unsafe {
                nm = string.new(this.names.ptr_at(off))
                fmt.printf("[tu/peff] undefined symbol: ")
                fmt.printf(nm)
                fmt.printf("\n")
                if nm == "runtime_win_fd_alloc_tu" || nm == "runtime_win_fd_get_tu" {
                    fmt.printf("[tu/peff] hint: Windows fd_table missing from stdlib; use default embed, or: make overlay-copkg TARGET=windows\n")
                }
                ast.undef_vocab_hint(nm)
            }
            return 1
        }
        slot<ImportSlot> = new ImportSlot
        slot.name_off = off
        slot.dll_id = dll
        slot.stub_off = emit_import_stub(this.text)
        slot.iat_off = 0
        this.slots.push(slot)
        i += 1
    }
    entry_off<i32> = this.names.intern_cstr(*"mainCRTStartup")
    if this.find_defined_off(entry_off) == null {
        fmt.printf("[tu/peff] missing mainCRTStartup (entry stub not linked?)\n")
        return 1
    }
    return 0
}

PeImage::apply_relocs(sec<ByteBuf>, sec_va<u64>, rels<std.Array>, text_va<u64>, data_va<u64>) i32 {
    seclen<i32> = sec.len
    i<i32> = 0
    while i < rels.used {
        r<ObjRel> = rels.addr[i]
        if r.address < 0 || r.address >= seclen {
            fmt.printf("[tu/peff] reloc address OOB\n")
            return 1
        }
        tva<u64> = 0
        verr<i32> = 0
        tva, verr = this.lookup_va_off(r.name_off, text_va, data_va)
        if verr != 0 {
            fmt.printf("[tu/peff] reloc undef %s\n", this.names.ptr_at(r.name_off))
            return 1
        }
        loc_va<u64> = sec_va + i32_u64(r.address)
        if r.ty == IMAGE_REL_AMD64_REL32 {
            // Overflow-safe: address + 4 may wrap i32.
            if seclen < 4 || r.address > seclen - 4 {
                fmt.printf("[tu/peff] REL32 OOB\n")
                return 1
            }
            old<u32> = sec.read_u32(r.address)
            oldi<i32> = u32_i32(old)
            loc4<u64> = loc_va + 4.(u64)
            disp<i64> = u64_i64(tva) + oldi - u64_i64(loc4)
            sec.set_u32_at(r.address, i64_u32(disp))
        } else if r.ty == IMAGE_REL_AMD64_ADDR64 {
            if seclen < 8 || r.address > seclen - 8 {
                fmt.printf("[tu/peff] ADDR64 OOB\n")
                return 1
            }
            old64<u64> = sec.read_u64(r.address)
            sec.set_u64_at(r.address, old64 + tva)
        } else {
            fmt.printf("[tu/peff] unsupported reloc type %d for %s\n", int(r.ty), this.names.ptr_at(r.name_off))
            return 1
        }
        i += 1
    }
    return 0
}

// Write IMAGE_SECTION_HEADER fields after the 8-byte name.
PeImage::write_section_rest(out<ByteBuf>, vsize<u32>, va<u32>, rawsz<u32>, rawoff<u32>, ch<u32>) {
    out.push_u32(vsize)
    out.push_u32(va)
    out.push_u32(rawsz)
    out.push_u32(rawoff)
    z<u32> = 0
    out.push_u32(z)
    out.push_u32(z)
    out.push_u16(z)
    out.push_u16(z)
    out.push_u32(ch)
}

// Offsets into PeImage.layout noscan blob.
L_IB<i32> = 0
L_FA<i32> = 8
L_SA<i32> = 12
L_HDRS<i32> = 16
L_IMAGE<i32> = 20
L_ENTRY<i32> = 24
L_TEXT_VSIZE<i32> = 28
L_TEXT_RVA<i32> = 32
L_TEXT_RAW<i32> = 36
L_TEXT_FILE<i32> = 40
L_RDATA_VSIZE<i32> = 44
L_RDATA_RVA<i32> = 48
L_RDATA_RAW<i32> = 52
L_RDATA_FILE<i32> = 56
L_DATA_VSIZE<i32> = 60
L_DATA_RVA<i32> = 64
L_DATA_RAW<i32> = 68
L_DATA_FILE<i32> = 72
L_IMPORT_RVA<i32> = 76
L_IMPORT_SIZE<i32> = 80
L_IAT_RVA<i32> = 84
L_IAT_SIZE<i32> = 88

PeImage::link(outfile) i32 {
    if this.objects.used <= 0 {
        fmt.printf("[tu/peff] no object files\n")
        return 1
    }
    this.merge()
    if this.pcln_expand() != 0 {
        return 1
    }
    if this.resolve_imports() != 0 {
        return 1
    }

    ib<u64> = pe_image_base()
    fa<u32> = PE_FILE_ALIGN
    sa<u32> = PE_SECT_ALIGN
    coff_hdr<i32> = 24
    sect_hdrs<i32> = 120
    hdr_need<i32> = PE_DOS_LEN + coff_hdr + PE_OPT_SIZE + sect_hdrs
    size_of_headers<u32> = pe_align_u32(i32_u32(hdr_need), fa)

    this.text.align_to(16, 0x90)
    this.data.align_to(8, 0)
    text_vsize<u32> = i32_u32(this.text.len)
    text_rva<u32> = sa
    text_raw<u32> = pe_align_u32(text_vsize, fa)
    if text_raw == 0.(u32) {
        text_raw = fa
    }
    text_file<u32> = size_of_headers
    text_va<u64> = ib + u32_u64(text_rva)

    rdata_rva<u32> = pe_align_u32(text_rva + text_vsize, sa)
    this.rdata = build_imports(this.slots, this.names, rdata_rva)
    rdata_vsize<u32> = i32_u32(this.rdata.len)
    rdata_raw<u32> = pe_align_u32(rdata_vsize, fa)
    if rdata_vsize == 0.(u32) {
        rdata_raw = fa
        rdata_vsize = 1
    }
    if rdata_raw == 0.(u32) {
        rdata_raw = fa
    }
    rdata_file<u32> = text_file + text_raw
    rdata_va<u64> = ib + u32_u64(rdata_rva)

    data_rva<u32> = pe_align_u32(rdata_rva + rdata_vsize, sa)
    data_vsize<u32> = i32_u32(this.data.len)
    data_raw<u32> = pe_align_u32(data_vsize, fa)
    if data_raw == 0.(u32) {
        data_raw = fa
    }
    if data_vsize == 0.(u32) {
        data_vsize = 1
    }
    data_file<u32> = rdata_file + rdata_raw
    data_va<u64> = ib + u32_u64(data_rva)

    si<i32> = 0
    while si < this.slots.used {
        sl<ImportSlot> = this.slots.addr[si]
        stub_va<u64> = text_va + u32_u64(sl.stub_off)
        iat_va<u64> = rdata_va + u32_u64(sl.iat_off)
        patch_stub(this.text, sl.stub_off, stub_va, iat_va)
        si += 1
    }

    fi<i32> = 0
    while fi < this.objects.used {
        f<CoffObject> = this.objects.addr[fi]
        if this.apply_relocs(this.text, text_va, f.text_rels, text_va, data_va) != 0 {
            return 1
        }
        if this.apply_relocs(this.data, data_va, f.data_rels, text_va, data_va) != 0 {
            return 1
        }
        fi += 1
    }
    if this.pcln_fill(text_va, data_va) != 0 {
        return 1
    }
    // Fresh locals only: earlier u32 slots in this frame get smashed across GC /
    // calls (Windows). Do not reuse fa/text_file/etc from the pre-reloc pass.
    ib2<u64> = pe_image_base()
    // Literals: package PE_FILE_ALIGN / pe_align via early-frame temps were
    // observed smashed after pcln GC on Windows; keep post-reloc math literal.
    fa2<u32> = 0x200.(u32)
    sa2<u32> = 0x1000.(u32)
    hdrs2<u32> = 512.(u32)
    ly0<ByteBuf> = this.layout
    ly0.set_u64_at(L_IB, ib2)
    ly0.set_u32_at(L_FA, fa2)
    ly0.set_u32_at(L_SA, sa2)
    ly0.set_u32_at(L_HDRS, hdrs2)
    fa2 = ly0.read_u32(L_FA)
    sa2 = ly0.read_u32(L_SA)
    hdrs2 = ly0.read_u32(L_HDRS)
    tv2<u32> = i32_u32(this.text.len)
    trva2<u32> = sa2
    traw2<u32> = pe_align_u32(tv2, fa2)
    if traw2 == 0.(u32) {
        traw2 = fa2
    }
    tfile2<u32> = hdrs2
    rrva2<u32> = pe_align_u32(trva2 + tv2, sa2)
    rv2<u32> = i32_u32(this.rdata.len)
    rraw2<u32> = pe_align_u32(rv2, fa2)
    if rv2 == 0.(u32) {
        rraw2 = fa2
        rv2 = 1
    }
    if rraw2 == 0.(u32) {
        rraw2 = fa2
    }
    rfile2<u32> = tfile2 + traw2
    drva2<u32> = pe_align_u32(rrva2 + rv2, sa2)
    dv2<u32> = i32_u32(this.data.len)
    draw2<u32> = pe_align_u32(dv2, fa2)
    if draw2 == 0.(u32) {
        draw2 = fa2
    }
    if dv2 == 0.(u32) {
        dv2 = 1
    }
    dfile2<u32> = rfile2 + rraw2
    img2<u32> = pe_align_u32(drva2 + dv2, sa2)

    entry_off2<i32> = this.names.intern_cstr(*"mainCRTStartup")
    tva2<u64> = ib2 + u32_u64(trva2)
    dva2<u64> = ib2 + u32_u64(drva2)
    eva2<u64> = 0
    eerr2<i32> = 0
    eva2, eerr2 = this.lookup_va_off(entry_off2, tva2, dva2)
    if eerr2 != 0 {
        fmt.printf("[tu/peff] missing mainCRTStartup VA\n")
        return 1
    }
    entry2<u32> = u64_u32(eva2 - ib2)

    // Commit file layout to noscan blob before further calls (stack u32s get smashed).
    ly<ByteBuf> = this.layout
    ly.set_u64_at(L_IB, ib2)
    ly.set_u32_at(L_FA, fa2)
    ly.set_u32_at(L_SA, sa2)
    ly.set_u32_at(L_HDRS, hdrs2)
    ly.set_u32_at(L_IMAGE, img2)
    ly.set_u32_at(L_ENTRY, entry2)
    ly.set_u32_at(L_TEXT_VSIZE, tv2)
    ly.set_u32_at(L_TEXT_RVA, trva2)
    ly.set_u32_at(L_TEXT_RAW, traw2)
    ly.set_u32_at(L_TEXT_FILE, tfile2)
    ly.set_u32_at(L_RDATA_VSIZE, rv2)
    ly.set_u32_at(L_RDATA_RVA, rrva2)
    ly.set_u32_at(L_RDATA_RAW, rraw2)
    ly.set_u32_at(L_RDATA_FILE, rfile2)
    ly.set_u32_at(L_DATA_VSIZE, dv2)
    ly.set_u32_at(L_DATA_RVA, drva2)
    ly.set_u32_at(L_DATA_RAW, draw2)
    ly.set_u32_at(L_DATA_FILE, dfile2)

    import_rva2<u32> = 0
    import_size2<u32> = 0
    iat_rva2<u32> = 0
    iat_size2<u32> = 0
    nslot2<i32> = this.slots.used
    if nslot2 > 0 {
        rrva_live<u32> = ly.read_u32(L_RDATA_RVA)
        import_rva2 = rrva_live
        ndll2<i32> = 0
        if count_dll_slots(this.slots, DLL_KERNEL32) > 0 {
            ndll2 += 1
        }
        if count_dll_slots(this.slots, DLL_SHELL32) > 0 {
            ndll2 += 1
        }
        if count_dll_slots(this.slots, DLL_WS2_32) > 0 {
            ndll2 += 1
        }
        if count_dll_slots(this.slots, DLL_SYNCH) > 0 {
            ndll2 += 1
        }
        import_size2 = i32_u32((ndll2 + 1) * 20)
        min_off2<u32> = 0xffffffff.(u32)
        max_end2<u32> = 0
        ii2<i32> = 0
        while ii2 < this.slots.used {
            sl2<ImportSlot> = this.slots.addr[ii2]
            off2<u32> = sl2.iat_off
            if off2 < min_off2 {
                min_off2 = off2
            }
            end2<u32> = off2 + 8.(u32)
            if end2 > max_end2 {
                max_end2 = end2
            }
            ii2 += 1
        }
        iat_rva2 = rrva_live + min_off2
        iat_size2 = max_end2 - min_off2 + 8.(u32)
    }
    ly.set_u32_at(L_IMPORT_RVA, import_rva2)
    ly.set_u32_at(L_IMPORT_SIZE, import_size2)
    ly.set_u32_at(L_IAT_RVA, iat_rva2)
    ly.set_u32_at(L_IAT_SIZE, iat_size2)
    return this.write_pe(outfile)
}

PeImage::write_pe(outfile) i32 {
    ly<ByteBuf> = this.layout
    data_file<u32> = ly.read_u32(L_DATA_FILE)
    data_raw<u32> = ly.read_u32(L_DATA_RAW)
    total_guess<i32> = u32_i32(data_file + data_raw)
    if total_guess < 4096 {
        total_guess = 4096
    }
    max_img<i32> = 67108864
    if total_guess > max_img {
        fmt.printf("[tu/peff] absurd image size %d (data_file=%d data_raw=%d)\n", int(total_guess), int(u32_i32(data_file)), int(u32_i32(data_raw)))
        return 1
    }
    out<ByteBuf> = ByteBuf::zeros(0)
    out.reserve(total_guess)
    if out.store == null {
        fmt.printf("[tu/peff] reserve failed need=%d\n", int(total_guess))
        return 1
    }

    out.push_u8(0x4d)
    out.push_u8(0x5a)
    i<i32> = 2
    while i < 60 {
        out.push_u8(0)
        i += 1
    }
    out.push_u32(i32_u32(PE_DOS_LEN))
    while out.len < PE_DOS_LEN {
        out.push_u8(0)
    }
    out.push_u8(0x50)
    out.push_u8(0x45)
    out.push_u8(0)
    out.push_u8(0)

    out.push_u16(i32_u32(IMAGE_FILE_MACHINE_AMD64))
    out.push_u16(3.(u32))
    z<u32> = 0
    out.push_u32(z)
    out.push_u32(z)
    out.push_u32(z)
    out.push_u16(i32_u32(PE_OPT_SIZE))
    out.push_u16(0x0023.(u32))

    text_vsize<u32> = ly.read_u32(L_TEXT_VSIZE)
    rdata_vsize<u32> = ly.read_u32(L_RDATA_VSIZE)
    data_vsize<u32> = ly.read_u32(L_DATA_VSIZE)
    entry_rva<u32> = ly.read_u32(L_ENTRY)
    text_rva<u32> = ly.read_u32(L_TEXT_RVA)
    ib<u64> = ly.read_u64(L_IB)
    sa<u32> = ly.read_u32(L_SA)
    fa<u32> = ly.read_u32(L_FA)
    size_of_image<u32> = ly.read_u32(L_IMAGE)
    size_of_headers<u32> = ly.read_u32(L_HDRS)
    import_rva<u32> = ly.read_u32(L_IMPORT_RVA)
    import_size<u32> = ly.read_u32(L_IMPORT_SIZE)
    iat_rva<u32> = ly.read_u32(L_IAT_RVA)
    iat_size<u32> = ly.read_u32(L_IAT_SIZE)
    text_raw<u32> = ly.read_u32(L_TEXT_RAW)
    text_file<u32> = ly.read_u32(L_TEXT_FILE)
    rdata_raw<u32> = ly.read_u32(L_RDATA_RAW)
    rdata_file<u32> = ly.read_u32(L_RDATA_FILE)
    data_rva<u32> = ly.read_u32(L_DATA_RVA)
    rdata_rva<u32> = ly.read_u32(L_RDATA_RVA)

    out.push_u16(PE_OPT_MAGIC)
    out.push_u8(1)
    out.push_u8(0)
    out.push_u32(text_vsize)
    out.push_u32(rdata_vsize + data_vsize)
    out.push_u32(z)
    out.push_u32(entry_rva)
    out.push_u32(text_rva)
    out.push_u64(ib)
    out.push_u32(sa)
    out.push_u32(fa)
    out.push_u16(6.(u32))
    out.push_u16(z)
    out.push_u16(z)
    out.push_u16(z)
    out.push_u16(6.(u32))
    out.push_u16(z)
    out.push_u32(z)
    out.push_u32(size_of_image)
    out.push_u32(size_of_headers)
    out.push_u32(z)
    out.push_u16(PE_SUBSYSTEM_CUI)
    out.push_u16(0x0100.(u32))
    stack_rsv<u64> = 0x100000
    commit_rsv<u64> = 0x1000
    out.push_u64(stack_rsv)
    out.push_u64(commit_rsv)
    out.push_u64(stack_rsv)
    out.push_u64(commit_rsv)
    out.push_u32(z)
    out.push_u32(16.(u32))

    di<i32> = 0
    while di < 16 {
        if di == 1 {
            out.push_u32(import_rva)
            out.push_u32(import_size)
        } else if di == 12 {
            out.push_u32(iat_rva)
            out.push_u32(iat_size)
        } else {
            out.push_u32(z)
            out.push_u32(z)
        }
        di += 1
    }

    ch_text<u32> = 0x60000020
    ch_rdata<u32> = 0x40000040
    ch_data<u32> = 0xc0000040
    out.push_u8(46)
    out.push_u8(116)
    out.push_u8(101)
    out.push_u8(120)
    out.push_u8(116)
    out.push_u8(0)
    out.push_u8(0)
    out.push_u8(0)
    this.write_section_rest(out, text_vsize, text_rva, text_raw, text_file, ch_text)
    out.push_u8(46)
    out.push_u8(114)
    out.push_u8(100)
    out.push_u8(97)
    out.push_u8(116)
    out.push_u8(97)
    out.push_u8(0)
    out.push_u8(0)
    this.write_section_rest(out, rdata_vsize, rdata_rva, rdata_raw, rdata_file, ch_rdata)
    out.push_u8(46)
    out.push_u8(100)
    out.push_u8(97)
    out.push_u8(116)
    out.push_u8(97)
    out.push_u8(0)
    out.push_u8(0)
    out.push_u8(0)
    this.write_section_rest(out, data_vsize, data_rva, data_raw, data_file, ch_data)

    out.pad_to(u32_i32(size_of_headers))
    out.append(this.text.ptr(), this.text.len)
    out.pad_to(u32_i32(text_file + text_raw))
    if this.rdata.len > 0 {
        out.append(this.rdata.ptr(), this.rdata.len)
    }
    out.pad_to(u32_i32(rdata_file + rdata_raw))
    if this.data.len > 0 {
        out.append(this.data.ptr(), this.data.len)
    }
    out.pad_to(u32_i32(data_file + data_raw))

    fp<i32> = utils.fopen(outfile, "w+")
    if fp <= 0 {
        fmt.printf("[tu/peff] cannot write %s\n", outfile)
        return 1
    }
    n64<u64> = out.len
    utils.fwrite(fp, out.bits(), n64)
    utils.fclose(fp)
    fmt.printf("[tu/peff] wrote PE %s (text=%d data=%d imports=%d size=%d)\n", outfile, int(this.text.len), int(this.data.len), int(this.slots.used), int(out.len))
    return 0
}
