use std
use string
use linker.linux
use linker.utils

TU_PCLN_PREFIX = "__tu_pcln."
const TU_PCLN_HDR_I<i32> = 24
const TU_PCLN_REC_I<i32> = 48
const TU_PCLN_MAGIC_U<u32> = 0xFFFFFFF2.(u32)

fn pcln_is_frag(name){
	if std.len(name) <= 10 {
		return false
	}
	rest = string.sub(name, 10)
	return "__tu_pcln." + rest == name
}

fn pcln_frag_func(name){
	return string.sub(name, 10)
}

// Merge __tu_pcln.* + __tu_ln.* into runtime_pclntab (exact-sized by allocAddr).
Linker::fillPclntab()
{
	if !std.exist("runtime_pclntab", this.symDef) {
		return true
	}
	dataSeg = this.segLists[".data"]
	tab_sym<linux.Elf64_Sym> = this.symDef["runtime_pclntab"].prov.symTab["runtime_pclntab"]
	tab_end_va<u64> = tab_sym.st_value
	if std.exist("runtime_pclntab_end", this.symDef) {
		end_sym<linux.Elf64_Sym> = this.symDef["runtime_pclntab_end"].prov.symTab["runtime_pclntab_end"]
		tab_end_va = end_sym.st_value
	}
	cap_u<u64> = 0.(u64)
	if tab_end_va > tab_sym.st_value {
		cap_u = tab_end_va - tab_sym.st_value
	}

	ncount<i32> = 0
	for(def : this.symDef){
		sname = def.name
		if !pcln_is_frag(sname) {
			continue
		}
		fname = pcln_frag_func(sname)
		if !std.exist(fname, this.symDef) {
			continue
		}
		ncount += 1
	}
	if ncount == 0 {
		return true
	}

	need_i<i32> = TU_PCLN_HDR_I + ncount * TU_PCLN_REC_I
	need_u<u64> = need_i.(u64)
	zero_u64<u64> = 0
	if cap_u > zero_u64 && need_u > cap_u {
		utils.error("pclntab: allocated size too small for functab")
	}

	baddr_u<u32> = *dataSeg.baseAddr
	tab_u<u32> = tab_sym.st_value.(u32)
	rel_u<u32> = tab_u - baddr_u
	span_u32<u32> = cap_u.(u32)
	need_as_u32<u32> = need_i.(u32)
	if span_u32 < need_as_u32 {
		span_u32 = need_as_u32
	}
	dst<i8*> = null
	found<i32> = 0
	for(v<Block> : dataSeg.blocks){
		if v.offset <= rel_u && rel_u + span_u32 <= v.offset + v.size {
			base<i8*> = v.data
			off_i<i32> = (rel_u - v.offset).(i32)
			dst = base + off_i
			found = 1
			break
		}
	}
	if found == 0 {
		utils.error("pclntab: cannot locate runtime_pclntab in .data")
	}

	cap_i<i32> = cap_u.(i32)
	zi<i32> = 0
	zero_n<i32> = cap_i
	if zero_n < need_i {
		zero_n = need_i
	}
	while zi < zero_n {
		zp<i8*> = dst + zi
		*zp = 0
		zi += 1
	}

	p0<u32*> = dst
	*p0 = TU_PCLN_MAGIC_U
	b4<i8*> = dst + 4
	*b4 = 1
	b5<i8*> = dst + 5
	*b5 = 8
	p8<u32*> = dst + 8
	*p8 = ncount.(u32)
	p12<u32*> = dst + 12
	*p12 = 0.(u32)
	p16<u32*> = dst + 16
	*p16 = TU_PCLN_HDR_I.(u32)
	pctab_off_i<i32> = need_i
	p20<u32*> = dst + 20
	*p20 = pctab_off_i.(u32)

	cursor_i<i32> = pctab_off_i
	o16u<u32> = 16.(u32)
	o24u<u32> = 24.(u32)
	o32u<u32> = 32.(u32)
	o36u<u32> = 36.(u32)
	o40u<u32> = 40.(u32)
	ri<i32> = 0
	for(def : this.symDef){
		sname = def.name
		if !pcln_is_frag(sname) {
			continue
		}
		fname = pcln_frag_func(sname)
		if !std.exist(fname, this.symDef) {
			continue
		}
		fsym<linux.Elf64_Sym> = this.symDef[fname].prov.symTab[fname]
		entry_u<u64> = fsym.st_value
		end_u<u64> = entry_u
		endname = "__tu_end_" + fname
		if std.exist(endname, this.symDef) {
			esym<linux.Elf64_Sym> = this.symDef[endname].prov.symTab[endname]
			end_u = esym.st_value
		}
		fr<linux.Elf64_Sym> = def.prov.symTab[sname]
		fva_u<u32> = fr.st_value.(u32)
		name_u<u64> = 0.(u64)
		file_u<u64> = 0.(u64)
		line_i<i32> = 0
		nlines_i<i32> = 0
		framesize_i<i32> = 0
		dataSeg.pcln_read_u64_into(fva_u + o16u, &name_u)
		dataSeg.pcln_read_u64_into(fva_u + o24u, &file_u)
		dataSeg.pcln_read_i32_into(fva_u + o32u, &line_i)
		dataSeg.pcln_read_i32_into(fva_u + o36u, &nlines_i)
		dataSeg.pcln_read_i32_into(fva_u + o40u, &framesize_i)

		pcln_off_u<u32> = 0.(u32)
		lnname = "__tu_ln." + fname
		if nlines_i > 0 && nlines_i < 100000 && std.exist(lnname, this.symDef) {
			chunk_i<i32> = 4 + nlines_i * 8
			if cursor_i + chunk_i <= cap_i {
				pcln_off_u = cursor_i.(u32)
				pn<u32*> = dst + cursor_i
				*pn = nlines_i.(u32)
				cursor_i += 4
				ln_sym<linux.Elf64_Sym> = this.symDef[lnname].prov.symTab[lnname]
				lnva_u<u32> = ln_sym.st_value.(u32)
				li<i32> = 0
				while li < nlines_i {
					pcva_u<u64> = 0.(u64)
					ln_i<i32> = 0
					stride<i32> = li * 16
					ent_u<u32> = stride.(u32)
					dataSeg.pcln_read_u64_into(lnva_u + ent_u, &pcva_u)
					eight<u32> = 8.(u32)
					dataSeg.pcln_read_i32_into(lnva_u + ent_u + eight, &ln_i)
					pc_off_u<u32> = 0.(u32)
					if pcva_u >= entry_u {
						pc_off_u = (pcva_u - entry_u).(u32)
					}
					po<u32*> = dst + cursor_i
					*po = pc_off_u
					pl<i32*> = dst + cursor_i + 4
					*pl = ln_i
					cursor_i += 8
					li += 1
				}
			}
		}

		off_i<i32> = TU_PCLN_HDR_I + ri * TU_PCLN_REC_I
		pu<u64*> = dst + off_i
		*pu = entry_u
		pu = dst + off_i + 8
		*pu = end_u
		pu = dst + off_i + 16
		*pu = name_u
		pu = dst + off_i + 24
		if strip_pcln_file != 0 {
			*pu = 0.(u64)
		} else {
			*pu = file_u
		}
		pi<i32*> = dst + off_i + 32
		*pi = line_i
		pu32<u32*> = dst + off_i + 36
		*pu32 = pcln_off_u
		pu32 = dst + off_i + 40
		*pu32 = framesize_i.(u32)
		pu32 = dst + off_i + 44
		*pu32 = 0.(u32)
		ri += 1
	}

	// Sort records by entry; swap full record bytes.
	i<i32> = 1
	while i < ncount {
		j<i32> = i
		while j > 0 {
			prev_off<i32> = TU_PCLN_HDR_I + (j - 1) * TU_PCLN_REC_I
			cur_off<i32> = TU_PCLN_HDR_I + j * TU_PCLN_REC_I
			p_prev<u64*> = dst + prev_off
			p_cur<u64*> = dst + cur_off
			if *p_cur >= *p_prev {
				break
			}
			k<i32> = 0
			while k < TU_PCLN_REC_I {
				a<i8*> = dst + prev_off + k
				b<i8*> = dst + cur_off + k
				tmp<i8> = *a
				*a = *b
				*b = tmp
				k += 1
			}
			j -= 1
		}
		i += 1
	}
	utils.debug("pclntab filled nfunc=", ncount)
	return true
}
