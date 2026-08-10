// Darwin pclntab expand + fill. Layout matches the ELF linker functab.

use std
use fmt

DARWIN_PCLN_MAGIC<u32> = 0xFFFFFFF2
DARWIN_PCLN_HDR_SIZE<i32> = 24
DARWIN_PCLN_REC_SIZE<i32> = 48
DARWIN_PCLN_FRAG_SIZE<i32> = 48
PCLN_ALIGN_MASK<u64> = 0xfffffffffffffff8

nm_pclntab = "runtime_pclntab"
nm_pclntab_end = "runtime_pclntab_end"
nm_pcln_pref = "__tu_pcln."
nm_end_pref = "__tu_end_"
nm_ln_pref = "__tu_ln."

mem PclnLineEnt {
    u32 pc_off
    i32 line
}

// Offsets + symbol pointers only. Darwin VAs stay in locals / noscan data.
mem PclnFrag {
    i32 fname_off
    i32 frag_off
    ImageSym* fn_sym
    ImageSym* end_sym
    i32 rec_line
    u32 framesize
    u32 pcln_off
    std.Array* lines
}

fn pcln_is_frag(tab<NameTab>, off<i32>) i32 {
    n<i32> = tab.len_at(off)
    if n <= 10 {
        return 0
    }
    p<i8*> = tab.ptr_at(off)
    pref<i8*> = *nm_pcln_pref
    if name_eq_bytes(p, pref, 10) == 0 {
        return 0
    }
    j<i32> = 10
    while j < n {
        if p[j] == '.' {
            return 0
        }
        j += 1
    }
    return 1
}

MachImage::pcln_need() u64 {
    tab_off<i32> = this.names.intern_cstr(*nm_pclntab)
    tab<ImageSym> = this.find_defined_off(tab_off)
    if tab == null {
        return 0
    }
    nfunc<u32> = 0
    pctab_bytes<u64> = 0
    i<i32> = 0
    while i < this.defined.len() {
        s<ImageSym> = this.defined.addr[i]
        if pcln_is_frag(this.names, s.name_off) == 0 {
            i += 1
            continue
        }
        fname_off<i32> = s.name_off + 10
        fname_n<i32> = this.names.len_at(fname_off)
        if this.find_defined_bytes(this.names.ptr_at(fname_off), fname_n) == null {
            i += 1
            continue
        }
        if s.n_sect != 2 {
            i += 1
            continue
        }
        nfunc += 1
        off_i<i32> = s.sect_off
        if off_i + DARWIN_PCLN_FRAG_SIZE <= this.data.len {
            nlines<i32> = this.data.read_i32(off_i + 36)
            if nlines > 0 {
                add<u64> = 4
                add = add + nlines * 8
                pctab_bytes = pctab_bytes + add
            }
        }
        i += 1
    }
    hdr<u64> = 24
    rec<u64> = 48
    nf<u64> = nfunc
    need<u64> = hdr + nf * rec + pctab_bytes
    need = (need + 7) & PCLN_ALIGN_MASK
    if need < hdr {
        need = hdr
    }
    return need
}

MachImage::pcln_expand() i32 {
    tab_off<i32> = this.names.intern_cstr(*nm_pclntab)
    tab<ImageSym> = this.find_defined_off(tab_off)
    if tab == null {
        return 0
    }
    need<u64> = this.pcln_need()
    if need == 0 {
        return 0
    }
    tab_sect<u64> = tab.sect_off
    hdr<u64> = 24
    end_off<u64> = tab_sect + hdr
    end_name<i32> = this.names.intern_cstr(*nm_pclntab_end)
    es<ImageSym> = this.find_defined_off(end_name)
    if es != null {
        end_off = es.sect_off
    }
    if end_off < tab_sect {
        end_off = tab_sect + hdr
    }
    stub_sz<u64> = end_off - tab_sect
    if stub_sz == 0 {
        stub_sz = hdr
    }
    if need > stub_sz {
        delta<u64> = need - stub_sz
        rem<u64> = delta % 8
        if rem != 0 {
            need = need + (8 - rem)
            delta = need - stub_sz
        }
        end_i<i32> = u64_i32(end_off)
        if end_i > this.data.len {
            fmt.printf("[tu/darwin] pclntab end past data\n")
            return 1
        }
        delta_i<i32> = u64_i32(delta)
        this.data.insert_zeros(end_i, delta_i)
        i<i32> = 0
        while i < this.defined.len() {
            s<ImageSym> = this.defined.addr[i]
            if s.n_sect == 2 && s.sect_off >= end_off {
                s.sect_off = s.sect_off + delta
            }
            i += 1
        }
        fi<i32> = 0
        while fi < this.objects.len() {
            f<MachObject> = this.objects.addr[fi]
            ri<i32> = 0
            while ri < f.data_rels.len() {
                r<ObjRel> = f.data_rels.addr[ri]
                addr_u<u64> = r.address
                if addr_u >= end_off {
                    add_i<i32> = delta
                    r.address = r.address + add_i
                }
                ri += 1
            }
            fi += 1
        }
    }
    if es != null {
        es.sect_off = tab_sect + need
    }
    return 0
}

MachImage::pcln_fill(text_sect_va<u64>, data_sect_va<u64>) i32 {
    pcln_lit<i8*> = *nm_pclntab
    tab<ImageSym> = this.find_defined_bytes(pcln_lit, cstr_len(pcln_lit))
    if tab == null {
        return 0
    }
    tab_off<u64> = tab.sect_off
    tab_end_off<u64> = tab_off
    end_lit<i8*> = *nm_pclntab_end
    es2<ImageSym> = this.find_defined_bytes(end_lit, cstr_len(end_lit))
    if es2 != null {
        tab_end_off = es2.sect_off
    }
    cap<u64> = 0
    if tab_end_off > tab_off {
        cap = tab_end_off - tab_off
    }

    end_pref<i8*> = *nm_end_pref
    ln_pref<i8*> = *nm_ln_pref
    frags<std.Array> = std.NewArray()
    i<i32> = 0
    while i < this.defined.len() {
        s<ImageSym> = this.defined.addr[i]
        if pcln_is_frag(this.names, s.name_off) == 0 {
            i += 1
            continue
        }
        fname_off<i32> = s.name_off + 10
        fname_n<i32> = this.names.len_at(fname_off)
        fs<ImageSym> = this.find_defined_bytes(this.names.ptr_at(fname_off), fname_n)
        if fs == null {
            i += 1
            continue
        }
        if s.n_sect != 2 {
            i += 1
            continue
        }
        fg<PclnFrag> = new PclnFrag
        fg.fname_off = fname_off
        fg.frag_off = u64_i32(s.sect_off)
        fg.fn_sym = fs
        fg.end_sym = this.find_defined_concat(end_pref, 9, this.names.ptr_at(fname_off), fname_n)
        entry_va<u64> = this.sym_va(fs, text_sect_va, data_sect_va)
        foff<i32> = fg.frag_off
        nlines<i32> = this.data.read_i32(foff + 36)
        fsz<i32> = this.data.read_i32(foff + 40)
        fg.rec_line = this.data.read_i32(foff + 32)
        fg.framesize = fsz
        fg.pcln_off = 0
        fg.lines = std.NewArray()
        lns<ImageSym> = this.find_defined_concat(ln_pref, 8, this.names.ptr_at(fname_off), fname_n)
        if nlines > 0 && lns != null {
            if lns.n_sect == 2 {
                ln_off<i32> = u64_i32(lns.sect_off)
                li<i32> = 0
                while li < nlines {
                    pcva<u64> = this.data.read_u64(ln_off + li * 16)
                    ln<i32> = this.data.read_i32(ln_off + li * 16 + 8)
                    e<PclnLineEnt> = new PclnLineEnt
                    e.pc_off = 0
                    if pcva >= entry_va {
                        e.pc_off = u64_u32(pcva - entry_va)
                    }
                    e.line = ln
                    fg.lines.push(e)
                    li += 1
                }
            }
        }
        frags.push(fg)
        i += 1
    }

    // Sort frags by entry VA (insertion sort).
    a<i32> = 1
    while a < frags.len() {
        fg<PclnFrag> = frags.addr[a]
        b<i32> = a
        loop {
            if b <= 0 {
                break
            }
            prev_i<i32> = b - 1
            prev<PclnFrag> = frags.addr[prev_i]
            if prev.fn_sym.sect_off <= fg.fn_sym.sect_off {
                break
            }
            frags.addr[b] = prev
            b -= 1
        }
        frags.addr[b] = fg
        a += 1
    }

    nfi<i32> = frags.len()
    nfunc<u32> = i32_u32(nfi)
    pctab_bytes<u64> = 0
    four<u64> = 4
    eight<u64> = 8
    i = 0
    while i < frags.len() {
        fg<PclnFrag> = frags.addr[i]
        if fg.lines.len() > 0 {
            nli<i32> = fg.lines.len()
            nl64<u64> = nli
            pctab_bytes = pctab_bytes + four + nl64 * 8
        }
        i += 1
    }
    hdr_sz<u64> = 24
    rec_sz<u64> = 48
    nf64<u64> = nfunc
    need<u64> = hdr_sz + nf64 * rec_sz + pctab_bytes
    need = (need + 7) & PCLN_ALIGN_MASK
    if cap > 0 && need > cap {
        fmt.printf("[tu/darwin] pclntab need %d > cap %d\n", int(u64_i32(need)), int(u64_i32(cap)))
        return 1
    }
    toff_i<i32> = u64_i32(tab_off)
    if toff_i + u64_i32(need) > this.data.len {
        fmt.printf("[tu/darwin] pclntab write OOB\n")
        return 1
    }
    dst<i8*> = this.data.ptr() + toff_i
    db<u64> = dst
    std.memset(db, 0, need)
    magic<u32> = DARWIN_PCLN_MAGIC
    std.memcpy(dst, &magic, four)
    dst[4] = 1
    dst[5] = 8
    std.memcpy(dst + 8, &nfunc, four)
    nfiles<u32> = 0
    std.memcpy(dst + 12, &nfiles, four)
    functabOff<u32> = 24
    std.memcpy(dst + 16, &functabOff, four)
    nf<i32> = nfunc
    pctabOff<u32> = i32_u32(24 + nf * 48)
    std.memcpy(dst + 20, &pctabOff, four)

    cursor<u32> = pctabOff
    i = 0
    while i < frags.len() {
        fg<PclnFrag> = frags.addr[i]
        if fg.lines.len() > 0 {
            fg.pcln_off = cursor
            nli2<i32> = fg.lines.len()
            n<u32> = i32_u32(nli2)
            cur_i<i32> = u32_i32(cursor)
            std.memcpy(dst + cur_i, &n, four)
            cursor = cursor + 4
            li<i32> = 0
            while li < fg.lines.len() {
                e<PclnLineEnt> = fg.lines.addr[li]
                cur_i = u32_i32(cursor)
                std.memcpy(dst + cur_i, &e.pc_off, four)
                std.memcpy(dst + cur_i + 4, &e.line, four)
                cursor = cursor + 8
                li += 1
            }
        }
        rec_off<i32> = 24 + i * 48
        entry_w<u64> = this.sym_va(fg.fn_sym, text_sect_va, data_sect_va)
        end_w<u64> = entry_w
        if fg.end_sym != null {
            end_w = this.sym_va(fg.end_sym, text_sect_va, data_sect_va)
        }
        name_w<u64> = this.data.read_u64(fg.frag_off + 16)
        file_w<u64> = this.data.read_u64(fg.frag_off + 24)
        rec_line<i32> = fg.rec_line
        std.memcpy(dst + rec_off, &entry_w, eight)
        std.memcpy(dst + rec_off + 8, &end_w, eight)
        std.memcpy(dst + rec_off + 16, &name_w, eight)
        std.memcpy(dst + rec_off + 24, &file_w, eight)
        std.memcpy(dst + rec_off + 32, &rec_line, four)
        std.memcpy(dst + rec_off + 36, &fg.pcln_off, four)
        std.memcpy(dst + rec_off + 40, &fg.framesize, four)
        pad<u32> = 0
        std.memcpy(dst + rec_off + 44, &pad, four)
        i += 1
    }
    fmt.printf("[tu/darwin] pclntab filled nfunc=%d need=%d\n", int(u32_i32(nfunc)), int(u64_i32(need)))
    return 0
}
