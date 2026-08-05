use std
use string
use linker.linux
use linker.utils

TU_PCLN_PREFIX = "__tu_pcln."
TU_PCLN_HDR_I<i32> = 24
TU_PCLN_REC_I<i32> = 40
TU_PCLN_MAGIC_U<u32> = 0xFFFFFFF1.(u32)

// True if name starts with "__tu_pcln.".
fn pcln_is_frag(name){
	pref = TU_PCLN_PREFIX
	pl = std.len(pref)
	if std.len(name) <= pl {
		return false
	}
	return pref + string.sub(name, pl) == name
}

fn pcln_frag_func(name){
	return string.sub(name, std.len(TU_PCLN_PREFIX))
}

// Merge __tu_pcln.* fragments into runtime_pclntab .data reserve.
// Writes native integers only (no dynamic Int boxing into the table).
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
	cap_u<u64> = tab_end_va - tab_sym.st_value

	// Pass 1: count fragments
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

	need_i<i32> = TU_PCLN_HDR_I + ncount * TU_PCLN_REC_I
	need_u<u64> = need_i.(u64)
	if cap_u > 0.(u64) && need_u > cap_u {
		utils.error("pclntab: runtime_pclntab reserve too small")
	}

	// Locate dst with native VAs (same *baseAddr pattern as relocAddr).
	baddr_u<u32> = *dataSeg.baseAddr
	tab_u<u32> = tab_sym.st_value.(u32)
	rel_u<u32> = tab_u - baddr_u
	need_u32<u32> = need_i.(u32)
	dst<i8*> = null
	found<i32> = 0
	for(v<Block> : dataSeg.blocks){
		if v.offset <= rel_u && rel_u + need_u32 <= v.offset + v.size {
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

	zi<i32> = 0
	while zi < need_i {
		zp<i8*> = dst + zi
		*zp = 0
		zi += 1
	}

	p0<u32*> = dst
	*p0 = TU_PCLN_MAGIC_U
	oi4<i32> = 4
	oi5<i32> = 5
	b4<i8*> = dst + oi4
	*b4 = 1
	b5<i8*> = dst + oi5
	*b5 = 8
	oi8<i32> = 8
	oi12<i32> = 12
	oi16<i32> = 16
	p8<u32*> = dst + oi8
	*p8 = ncount.(u32)
	p12<u32*> = dst + oi12
	*p12 = 0.(u32)
	p16<u32*> = dst + oi16
	*p16 = TU_PCLN_HDR_I.(u32)

	// Pass 2: write unsorted records with native st_value / relocated ptrs from fragments.
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
		dataSeg.pcln_read_u64_into(fva_u + 16.(u32), &name_u)
		dataSeg.pcln_read_u64_into(fva_u + 24.(u32), &file_u)
		dataSeg.pcln_read_i32_into(fva_u + 32.(u32), &line_i)

		off_i<i32> = TU_PCLN_HDR_I + ri * TU_PCLN_REC_I
		o0<i32> = off_i
		o8<i32> = off_i + 8
		o16b<i32> = off_i + 16
		o24<i32> = off_i + 24
		o32<i32> = off_i + 32
		o36<i32> = off_i + 36
		pu<u64*> = dst + o0
		*pu = entry_u
		pu = dst + o8
		*pu = end_u
		pu = dst + o16b
		*pu = name_u
		pu = dst + o24
		*pu = file_u
		pi<i32*> = dst + o32
		*pi = line_i
		pi = dst + o36
		*pi = 0
		ri += 1
	}

	// In-place insertion sort by entry (native u64).
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
			// Swap full 40-byte records
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
