use runtime
use linker.linux
use linker.utils
use asmer.ast
use fmt
use std
use std.map
use string
use os

trace<i32> = 0
strip_pcln_file<i32> = 0

fn link_mapstringhashkey(k<string.String>) u64 {
	return k.hash64()
}

// Linux ELF linker: collect objects, resolve symbols, layout, relocate, emit ET_EXEC.
mem Linker {
	map.Map*   segLists // string.String* -> Seglist*
	std.Array* symLinks // SymLink*
	map.Map*   symDef   // string.String* -> SymLink*
	std.Array* secDef   // SymLink*
	std.Array* elfs     // linux.File*
	std.Array* segNames // string.String*
	linux.File* exe
	linux.File* startOwner
	i32 bssaddr
	i32 pclntab_size
	i32 bytes
}

Linker::init(){
	utils.debug("Linker::init".(i8))
	this.exe = new linux.File()
	this.startOwner = null
	this.bssaddr = 0
	this.pclntab_size = 0
	this.bytes = 0

	this.segLists = map.map_new(link_mapstringhashkey.(u64), 0.(i8))
	this.symLinks = std.NewArray()
	this.symDef = map.map_new(link_mapstringhashkey.(u64), 0.(i8))
	this.secDef = std.NewArray()
	this.elfs = std.NewArray()
	this.segNames = std.NewArray()

	this.segNames.push(string.S(*".text"))
	this.segNames.push(string.S(*".data"))
	this.segNames.push(string.S(*".bss"))
	this.segNames.push(string.S(*".rodata"))
	this.segNames.push(string.S(*".data.rel.local"))

	i<i32> = 0
	while i < this.segNames.used {
		name<string.String> = this.segNames.addr[i]
		this.segLists.insert(name, new Seglist())
		i += 1
	}
}

Linker::addElf(path<string.String>){
	utils.debug("Linker::addElf add a elffile".(i8))
	e<linux.File> = new linux.File()
	e.readElf(path)
	this.elfs.push(e)
}

// Dyn-ABI facades for linker/main (unsafe dyn CLI) to drive mem Linker.
export func linker_new() {
	return new Linker()
}
export func linker_add_elf(l, obj) {
	lk<Linker> = l
	path<string.String> = linux.file_path_from_dyn(obj)
	lk.addElf(path)
}
export func linker_link(l, out) {
	lk<Linker> = l
	path<string.String> = linux.file_path_from_dyn(out)
	// Box i32 for dyn callers (main compares return with == 0).
	return int(lk.link(path))
}

Linker::collectInfo(){
	utils.msg(30, "Collecting object info")
	ei<i32> = 0
	while ei < this.elfs.used {
		e<linux.File> = this.elfs.addr[ei]
		utils.debug("Collect object info %S".(i8), e.elfdir.str())
		si<i32> = 0
		while si < this.segNames.used {
			seg<string.String> = this.segNames.addr[si]
			if e.shdrTab.find(seg) != map.Null {
				sl<Seglist> = this.segLists.find(seg)
				sl.ownerList.push(e)
			}
			si += 1
		}
		iter<map.MapIter> = e.symTab.iter()
		while iter.next() != map.End {
			name<string.String> = iter.k()
			sym<linux.Elf64_Sym> = iter.v()
			symLink<SymLink> = new SymLink()
			symLink.name = name
			if sym.st_name == 0 {
				utils.debug("found sec sym: %S".(i8), name.str())
				symLink.prov = e
				symLink.recv = null
				this.secDef.push(symLink)
			} else if sym.st_shndx == linux.SHN_UNDEF {
				utils.debug("found undef sym: %S".(i8), name.str())
				symLink.recv = e
				symLink.prov = null
				this.symLinks.push(symLink)
			} else if sym.st_shndx != linux.SHN_ABS {
				utils.debug("found sym: %S".(i8), name.str())
				symLink.prov = e
				symLink.recv = null
				if this.symDef.find(symLink.name) != map.Null {
					def<SymLink> = this.symDef.find(symLink.name)
					defm<linux.Elf64_Sym> = def.prov.symTab.find(def.name)
					bind<u8> = defm.st_info >> 4
					if bind == linux.STB_GLOBAL.(u8) {
						utils.errorf(
							"symbol conflict: %s file:%s  from:%s",
							name.dyn(0), e.elfdir.dyn(0), def.prov.elfdir.dyn(0)
						)
					}
				}
				this.symDef.insert(symLink.name, symLink)
			}
		}
		ei += 1
	}
}

Linker::symValid() i32 {
	utils.msg(40, "Checking symbol valid")
	flag<i32> = 1

	if this.symDef.find(string.S(*"main")) == map.Null {
		os.die("not entry address: main")
	}

	this.startOwner = null
	startLink<SymLink> = this.symDef.find(string.S(*"main"))
	ui<i32> = 0
	while ui < this.symLinks.used {
		undefine<SymLink> = this.symLinks.addr[ui]
		if this.symDef.find(undefine.name) != map.Null {
			def<SymLink> = this.symDef.find(undefine.name)
			undefine.prov = def.prov
			def.recv = def.prov
		} else {
			msym<linux.Elf64_Sym> = undefine.recv.symTab.find(undefine.name)
			info<u8> = msym.st_info
			stype<u8> = info & 0xf
			type_s<string.String> = string.S(*"symbol")
			if stype == linux.STT_OBJECT.(u8) {
				type_s = string.S(*"variable")
			}
			if stype == linux.STT_FUNC.(u8) {
				type_s = string.S(*"function")
			}
			utils.debug("file undefine".(i8))
			unsafe {
				ast.undef_vocab_hint(undefine.name.dyn(0))
			}
			if flag == 1 {
				utils.errorf(
					"file:%s type:%s var:%s undefine",
					undefine.recv.elfdir.dyn(0),
					type_s.dyn(0),
					undefine.name.dyn(0)
				)
				flag = 0
			}
		}
		ui += 1
	}
	utils.debug("done symValid %d".(i8), flag)
	return flag
}

Linker::allocAddr(){
	utils.msg(50, "Allocing address ")
	curAddr<i32> = BASE_ADDR
	curOff<i32> = linux.ELF64_EHDR_SIZE + linux.ELF64_PHDR_SIZE * this.segNames.used.(i32)
	need_u<u32> = this.computePclntabNeed()

	si<i32> = 0
	while si < this.segNames.used {
		seg<string.String> = this.segNames.addr[si]
		pass_need<u32> = 0
		if seg.cmpstr(*".data") == string.Equal {
			pass_need = need_u
		}
		sl<Seglist> = this.segLists.find(seg)
		sl.allocAddr(seg, &curAddr, &curOff, pass_need)
		si += 1
	}
	this.bssaddr = curAddr
}

// Scan __tu_pcln.* before allocAddr; st_value still section-relative.
Linker::computePclntabNeed() u32 {
	this.pclntab_size = 0
	if this.symDef.find(string.S(*"runtime_pclntab")) == map.Null {
		return 0
	}
	hdr_sz<i32> = 24
	rec_sz<i32> = 48
	nfunc<i32> = 0
	pctab_i<i32> = 0
	iter<map.MapIter> = this.symDef.iter()
	while iter.next() != map.End {
		def<SymLink> = iter.v()
		sname<string.String> = def.name
		if pcln_is_frag(sname) == 0 {
			continue
		}
		fname<string.String> = pcln_frag_func(sname)
		if this.symDef.find(fname) == map.Null {
			continue
		}
		nfunc += 1
		prov<linux.File> = def.prov
		if prov.shdrTab.find(string.S(*".data")) == map.Null {
			continue
		}
		data_sh<linux.Elf64_Shdr> = prov.shdrTab.find(string.S(*".data"))
		fr<linux.Elf64_Sym> = prov.symTab.find(sname)
		off_u<u64> = fr.st_value
		sz_u<u64> = data_sh.sh_size
		frag_u<u64> = 48
		if off_u + frag_u <= sz_u {
			tmp_i<i32> = 0
			bufp<i8*> = new 4
			thirtysix_u<u64> = 36
			four_u<u64> = 4
			prov.getData(bufp, data_sh.sh_offset + off_u + thirtysix_u, four_u)
			tp<i32*> = bufp
			tmp_i = *tp
			if tmp_i > 0 {
				pctab_i += 4 + tmp_i * 8
			}
		}
	}
	need_i<i32> = hdr_sz + nfunc * rec_sz + pctab_i
	need_i = need_i + 3
	need_i = need_i - need_i % 4
	if need_i < hdr_sz {
		need_i = hdr_sz
	}
	this.pclntab_size = need_i
	return need_i.(u32)
}

// After symParser: end = start + need for lea/cap.
Linker::fixPclntabEnd() i32 {
	ps<i32> = this.pclntab_size
	if ps == 0 {
		return 1
	}
	if this.symDef.find(string.S(*"runtime_pclntab")) == map.Null {
		return 1
	}
	if this.symDef.find(string.S(*"runtime_pclntab_end")) == map.Null {
		return 1
	}
	start_sl<SymLink> = this.symDef.find(string.S(*"runtime_pclntab"))
	end_sl<SymLink> = this.symDef.find(string.S(*"runtime_pclntab_end"))
	start_sym<linux.Elf64_Sym> = start_sl.prov.symTab.find(string.S(*"runtime_pclntab"))
	end_sym<linux.Elf64_Sym> = end_sl.prov.symTab.find(string.S(*"runtime_pclntab_end"))
	end_sym.st_value = start_sym.st_value + ps.(u64)
	si<i32> = 0
	while si < this.symLinks.used {
		sym<SymLink> = this.symLinks.addr[si]
		if sym.name.cmpstr(*"runtime_pclntab_end") == string.Equal {
			if sym.recv != null {
				if sym.recv.symTab.find(string.S(*"runtime_pclntab_end")) != map.Null {
					rs<linux.Elf64_Sym> = sym.recv.symTab.find(string.S(*"runtime_pclntab_end"))
					rs.st_value = end_sym.st_value
				}
			}
		}
		si += 1
	}
	return 1
}

Linker::symParser(){
	utils.msg(60, "Relocating symbol")
	iter<map.MapIter> = this.symDef.iter()
	while iter.next() != map.End {
		def<SymLink> = iter.v()
		sym<linux.Elf64_Sym> = def.prov.symTab.find(def.name)
		segName<string.String> = null
		if sym.st_shndx == linux.SHN_COMMON {
			segName = string.S(*".bss")
		} else {
			shndx<i32> = sym.st_shndx.(i32)
			segName = def.prov.shdrNames.addr[shndx]
		}
		if segName.cmpstr(*".bss") == string.Equal && def.name.cmpstr(*".bss") != string.Equal {
			this.bssaddr += sym.st_size.(i32)
			sym.st_value = this.bssaddr.(u64)
		} else {
			sh<linux.Elf64_Shdr> = def.prov.shdrTab.find(segName)
			sym.st_value = sym.st_value + sh.sh_addr
		}
	}
	utils.debug("secDef parse".(i8))
	sci<i32> = 0
	while sci < this.secDef.used {
		sec<SymLink> = this.secDef.addr[sci]
		sec_sym<linux.Elf64_Sym> = sec.prov.symTab.find(sec.name)
		sec_shndx<i32> = sec_sym.st_shndx.(i32)
		segName2<string.String> = sec.prov.shdrNames.addr[sec_shndx]

		if segName2.cmpstr(*".bss") == string.Equal && sec.name.cmpstr(*".bss") != string.Equal {
			this.bssaddr += sec_sym.st_size.(i32)
			sec_sym.st_value = this.bssaddr.(u64)
		} else {
			sec_sh<linux.Elf64_Shdr> = sec.prov.shdrTab.find(segName2)
			sec_sym.st_value = sec_sym.st_value + sec_sh.sh_addr
		}
		sci += 1
	}
	sli<i32> = 0
	while sli < this.symLinks.used {
		syml<SymLink> = this.symLinks.addr[sli]
		provsym<linux.Elf64_Sym> = syml.prov.symTab.find(syml.name)
		recvsym<linux.Elf64_Sym> = syml.recv.symTab.find(syml.name)
		recvsym.st_value = provsym.st_value
		sli += 1
	}
}

Linker::relocate(){
	utils.msg(80, "Relocating address")
	ei<i32> = 0
	while ei < this.elfs.used {
		e<linux.File> = this.elfs.addr[ei]
		tab<std.Array> = e.relTab
		ti<i32> = 0
		while ti < tab.len() {
			t<linux.RelItem> = tab.addr[ti]
			utils.debug("relocate item".(i8))
			if t.relname.empty() == string.True {
				ti += 1
				continue
			}
			symname<string.String> = t.relname
			sym<linux.Elf64_Sym> = e.symTab.find(symname)
			rel<linux.Elf64_Rela> = t.rel
			sh<linux.Elf64_Shdr> = e.shdrTab.find(t.segname)
			symAddr<u32> = (sym.st_value + rel.r_addend).(u32)
			relAddr<u32> = (sh.sh_addr + rel.r_offset).(u32)
			obj<Seglist> = this.segLists.find(t.segname)
			rinfo2<i64> = rel.r_info.(i64)
			rtype<u8> = (rinfo2 & 0xffffffff).(u8)
			obj.relocAddr(relAddr, rtype, symAddr, rel.r_addend.(i32))
			ti += 1
		}
		ei += 1
	}
}
