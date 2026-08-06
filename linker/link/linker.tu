use runtime
use linker.linux
use linker.utils
use fmt

bytes
trace
strip_pcln_file = 0 // zero file fields in PclnRec when non-zero

class Linker
{
	segLists = {}		// map[string]SegList
	symLinks = []		// arr[SymLink*]
	symDef	 = {}		// map[string]symLink*
	secDef	 = []		// arr[symLink*]
	elfs	 = []		// arr[elf,elf,elf]
	segNames = [ 		// arr[string] 
		".text" , ".data" , 
		".bss"  ,
		".rodata" , ".data.rel.local"
	]		
	exe				    // File* 
	startOwner			// _start owner file
	bssaddr  = 0
	pclntab_size = 0    // exact need bytes after computePclntabNeed
	bytes
}
Linker::init(){
	utils.debug("Linker::init")
	file = new linux.File()
	this.exe = file

	sl = this.segLists
	for(name : this.segNames){
		sl[name] = new Seglist()
	}
}
Linker::addElf(obj)
{
	utils.debug("Linker::addElf add a elffile:",obj)
	e = new linux.File()
	e.readElf(obj)
	this.elfs[] = e
}
Linker::collectInfo()
{
	utils.msg(30,"Collecting object info")
	Null<i8> = 0
	for(e : this.elfs){
		utils.debug("Collect object info " + e.elfdir)
		for(seg : this.segNames){
			if std.exist(seg,e.shdrTab) {
				this.segLists[seg].ownerList[] = e
			}
		}
		for(name,sym<linux.Elf64_Sym> : e.symTab){
			symLink = new SymLink()
			symLink.name = name
			if sym.st_name == 0 {
				utils.debug("found sec sym:",name)
				symLink.prov = e
				symLink.recv = null
				this.secDef[] = symLink
			}else if  sym.st_shndx == linux.SHN_UNDEF {
				utils.debug("found undef sym:",name)
				symLink.recv = e
				symLink.prov = null
				this.symLinks[] = symLink
			}else if  sym.st_shndx != linux.SHN_ABS {
				utils.debug("found sym:",name)
				symLink.prov = e
				symLink.recv = null
				if std.exist(symLink.name,this.symDef) {
					def = this.symDef[symLink.name]
					defm<linux.Elf64_Sym> = def.prov.symTab[def.name]
					if linux.ELF64_ST_BIND(defm.st_info) == linux.STB_GLOBAL {
						utils.errorf(
							"symbol conflict: %s file:%s  from:%s",
							symLink.name,e.elfdir,def.prov.elfdir
						)
					}
				}
				this.symDef[symLink.name] = symLink
			}

		}
	}

}

Linker::symValid()
{
	utils.msg(40,"Checking symbol valid")
	flag = true

	if !std.exist("main",this.symDef) {
		os.die("not entry address: main")
	}

	startOwner = this.symDef["main"]
	for(undefine : this.symLinks){
		if std.exist(undefine.name , this.symDef) {
			def = this.symDef[undefine.name]
			undefine.prov = def.prov 
			def.recv = def.prov

		} else {
			msym<linux.Elf64_Sym> = undefine.recv.symTab[undefine.name]
			info<u8> = msym.st_info
			type = ""
			if   linux.ELF64_ST_TYPE(info)  == linux.STT_OBJECT {
				type = "variable"
			}
			if   linux.ELF64_ST_TYPE(info)  == linux.STT_FUNC {
				type = "function"
			}
			if  type == "" {
				type = "symbol"
			}
			utils.debug("file:%s type:%s var:%s undefine",undefine.recv.elfdir,type,undefine.name)
			if  flag {
				utils.errorf(
					"file:%s type:%s var:%s undefine",
					undefine.recv.elfdir,
					type,
					undefine.name
				)
				flag = false
			}
		}
	}
	utils.debug("done symValid",flag)
	return flag
}
Linker::allocAddr()
{
	utils.msg(50,"Allocing address ")
	curAddr<i32> = BASE_ADDR
	curOff = int(sizeof(linux.Elf64_Ehdr)) + int(sizeof(linux.Elf64_Phdr)) * std.len(this.segNames)
	//for reference
	mcurOff<i32> = *curOff
	need_u<u32> = this.computePclntabNeed()

	for(seg : this.segNames){
		pass_need<u32> = 0
		if seg == ".data" {
			pass_need = need_u
		}
		this.segLists[seg].allocAddr(seg,&curAddr,&mcurOff,pass_need)
	}
	this.bssaddr = int(curAddr)
}

// Scan __tu_pcln.* before allocAddr; st_value still section-relative.
Linker::computePclntabNeed()
{
	this.pclntab_size = 0
	if !std.exist("runtime_pclntab", this.symDef) {
		return 0
	}
	hdr_sz<i32> = 24
	rec_sz<i32> = 48
	nfunc<i32> = 0
	pctab_i<i32> = 0
	for(def : this.symDef){
		sname = def.name
		if !pcln_is_frag(sname) {
			continue
		}
		fname = pcln_frag_func(sname)
		if !std.exist(fname, this.symDef) {
			continue
		}
		nfunc += 1
		prov = def.prov
		if !std.exist(".data", prov.shdrTab) {
			continue
		}
		data_sh<linux.Elf64_Shdr> = prov.shdrTab[".data"]
		fr<linux.Elf64_Sym> = prov.symTab[sname]
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
	ret_u<u32> = need_i.(u32)
	return ret_u
}

// After symParser: end = start + need for lea/cap.
Linker::fixPclntabEnd()
{
	ps<i32> = this.pclntab_size
	if ps == 0 {
		return true
	}
	if !std.exist("runtime_pclntab", this.symDef) {
		return true
	}
	if !std.exist("runtime_pclntab_end", this.symDef) {
		return true
	}
	start_sym<linux.Elf64_Sym> = this.symDef["runtime_pclntab"].prov.symTab["runtime_pclntab"]
	end_sym<linux.Elf64_Sym> = this.symDef["runtime_pclntab_end"].prov.symTab["runtime_pclntab_end"]
	end_sym.st_value = start_sym.st_value + ps.(u64)
	for(sym : this.symLinks){
		if sym.name == "runtime_pclntab_end" {
			if sym.recv != null {
				if std.exist("runtime_pclntab_end", sym.recv.symTab) {
					rs<linux.Elf64_Sym> = sym.recv.symTab["runtime_pclntab_end"]
					rs.st_value = end_sym.st_value
				}
			}
		}
	}
	return true
}

Linker::symParser()
{
	utils.msg(60,"Relocating symbol")
	for(def : this.symDef){
		sym<linux.Elf64_Sym> = def.prov.symTab[def.name]
		segName = ""
		if  sym.st_shndx == linux.SHN_COMMON {
			segName = ".bss"
		}else{
			segName = def.prov.shdrNames[int(sym.st_shndx)]
		}
		if  segName == ".bss" && def.name != ".bss" {
			this.bssaddr += int(sym.st_size)
			sym.st_value = *this.bssaddr
		}else{
			sh<linux.Elf64_Shdr> = def.prov.shdrTab[segName]
			sym.st_value = sym.st_value + sh.sh_addr
		}
	}
	utils.debug("secDef parse")
	for(sec : this.secDef){
		sec_sym<linux.Elf64_Sym> = sec.prov.symTab[sec.name]
		segName = sec.prov.shdrNames[int(sec_sym.st_shndx)]

		if  segName == ".bss" && sec.name != ".bss" {
			this.bssaddr += int(sec_sym.st_size)
			sec_sym.st_value = *this.bssaddr
		}else{
			sec_sh<linux.Elf64_Shdr> = sec.prov.shdrTab[segName]
			sec_sym.st_value = sec_sym.st_value + sec_sh.sh_addr
		}
	}
	for(syml : this.symLinks){
		provsym<linux.Elf64_Sym> = syml.prov.symTab[syml.name]
		recvsym<linux.Elf64_Sym> = syml.recv.symTab[syml.name]
		recvsym.st_value = provsym.st_value
	}
}

Linker::relocate()
{
	utils.msg(80,"Relocating address")
	for(e : this.elfs){
		//TODO: copy on write
		tab = e.relTab
		for(t : tab){
			utils.debug(t,t.relname)
			if  t.relname == "" {
				continue
			}
			symname = t.relname
			sym<linux.Elf64_Sym> = e.symTab[symname]
			rel<linux.Elf64_Rela> = t.rel
			sh<linux.Elf64_Shdr> = e.shdrTab[t.segname]
			file = e.elfdir
			symAddr<u32> = sym.st_value + rel.r_addend
			relAddr<u32> = sh.sh_addr + rel.r_offset
			obj = this.segLists[t.segname]
			obj.relocAddr(relAddr,linux.ELF64_R_TYPE(rel.r_info),symAddr,rel.r_addend)
		}
	}
}