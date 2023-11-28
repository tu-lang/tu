use linker.linux
use linker.utils
use fmt

bytes
trace

class Linker
{
	segLists = {}		# map[string]SegList
	symLinks = []		# arr[SymLink*]
	symDef	 = {}		# map[string]symLink*
	secDef	 = []		# arr[symLink*]
	elfs	 = []		# arr[elf,elf,elf]
	segNames = [ 		# arr[string] 链接关心的段
		".text" , ".data" , 
		".bss"  ,
		".rodata" , ".data.rel.local"
	]		
	exe				    # File* 最后输出的文件
	startOwner			# 拥有全局符号start _start的文件
	bssaddr  = 0
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
	# 解析elf文件
	e.readElf(obj)
	this.elfs[] = e
}
use runtime
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
							"符号名定义冲突: %s file:%s  from:%s",
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
				type = "变量"
			}
			if   linux.ELF64_ST_TYPE(info)  == linux.STT_FUNC {
				type = "函数"
			}
			if  type == "" {
				type = "符号"
			}
			utils.debug("文件%s的%s名%s未定义",undefine.recv.elf_dir,type,undefine.name)
			if  flag {
				utils.errorf(
					"文件%s的%s名%s未定义",
					undefine.recv.elf_dir,
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

	for(seg : this.segNames){
		this.segLists[seg].allocAddr(seg,&curAddr,&mcurOff)
	}
	this.bssaddr = int(curAddr)
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