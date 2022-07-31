use linux
use fmt

#统计读写的字节数
bytes

class Linker
{
	segLists		# map[string]SegList
	symLinks		# arr[SymLink*]
	symDef			# map[string]symLink*
	secDef			# arr[symLink*]
	elfs			# arr[elf,elf,elf]
	segNames		# arr[string] 链接关心的段
	exe				# File* 最后输出的文件
	startOwner		# 拥有全局符号start _start的文件
	bssaddr
	bytes
}
Linker::init(){
	utils.debug("Linker::init")
	this.segNames = []
	this.bssaddr  = 0
	this.elfs = []
	this.symLinks = []
	this.symDef   = {}
	this.secDef   = []
	this.segLists = {}
	file = new linux.File()
	this.exe = file

	this.linker()
}
# 初始化
Linker::linker()
{
	utils.debug("Linker::linker")
	this.segNames[] = ".text"
	this.segNames[] = ".data"
	this.segNames[] = ".rodata"
	this.segNames[] = ".data.rel.local"
	this.segNames[] = ".bss"
	sl = this.segLists
	for(name : segNames){
		tmp = new Seglist()
		sl[name] = tmp
	}
}
# 1. 解析elf文件
# 2. 追加到待链接数组中等待链接
Linker::addElf(obj)
{
	utils.debug("Linker::addElf add a elffile:",obj)
	e = new linux.File()
	# 解析elf文件
	e.readElf(obj)
	this.elfs[] = e
}
use runtime
# 开始扫描文件搜集所有信息
Linker::collectInfo()
{
	utils.msg(30,"Collecting object info")
	Null<i8> = 0
	for(e : this.elfs){
		utils.debug("Collect object info " + e.elfdir)
		# 记录段表信息
		for(seg : this.segNames){
			if  e.shdrTab[seg] != runtime.Null  {
				tmp = this.segLists[seg].ownerList
				# TODO: copy on write 
				tmp[] = e
			}
		}
		# 记录符号引用信息
		for(name,sym<linux.Elf64_Sym> : e.symTab){
			symLink = new SymLink()
			symLink.name = name
			if sym.st_name == 0 {
				//utils.debug(name, " 段符号定义 ")
				symLink.prov = e
				symLink.recv = null
				this.secDef[] = symLink
			}else if  sym.st_shndx == linux.SHN_UNDEF {
				//utils.debug(name, " 未定义 ")
				symLink.recv = e
				symLink.prov = null
				this.symLinks[] = symLink
			}else if  sym.st_shndx != linux.SHN_ABS {
				//utils.debug(name, " 已定义")
				symLink.prov = e
				symLink.recv = null
				exist<u64> = this.symDef[symLink.name]
				if exist != null {
					def = this.symDef[symLink.name]
					utils.debug("符号名定义冲突: ",symLink.name,e.elfdir,def.prov.elfdir)
					os.exit(-1)
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

	exist<u64> = this.symDef["main"]
	if exist == null os.die("链接器找不到入口程序:main")

	startOwner = this.symDef["main"]
	# 遍历未定义的符号
	for(undefine : this.symLinks){
		exist = this.symDef[undefine.name]
		if exist != null {
			def = this.symDef[undefine.name]
			undefine.prov = def.prov //绑定未定义符号源定义处
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
			utils.debug("文件%s的%s名%s为定义",undefine.recv.elf_dir,type,undefine.name)
			if  flag {
				flag = false
			}
		}
	}
	utils.debug("done symValid",flag)
	return flag
}
# 分配地址空间
Linker::allocAddr()
{
	utils.msg(50,"Allocing address ")
	curAddr<i32> = BASE_ADDR
	curOff = int(sizeof(linux.Elf64_Ehdr)) + int(sizeof(linux.Elf64_Phdr)) * std.len(segNames)
	//for reference
	mcurOff<i32> = *curOff

	for(seg : this.segNames){
		//TODO: support chain access object.func
		//this.segLists[seg].allocAddr(seg,&curAddr,&mcurOff)
		obj = this.segLists[seg]
		obj.allocAddr(seg,&curAddr,&mcurOff)
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

		if  segName == ".bss" && def.name != ".bss" {
			this.bssaddr += int(sec_sym.st_size)
			sec_sym.st_value = *this.bssaddr
		}else{
			sec_sh<linux.Elf64_Shdr> = sec.prov.shdrTab[segName]
			sec_sym.st_value = sec_sym.st_value + sec_sh.sh_addr
		}
	}
	utils.debug("未定义符号解析")
	for(syml : this.symLinks){
		provsym<linux.Elf64_Sym> = syml.prov.symTab[syml.name]
		recvsym<linux.Elf64_Sym> = syml.recv.symTab[syml.name]
		recvsym.st_value = provsym.st_value
	}
}

# 重定位
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
			# 开始重定位操作
			obj = this.segLists[t.segname]
			obj.relocAddr(relAddr,linux.ELF64_R_TYPE(rel.r_info),symAddr,rel.r_addend)
		}
	}
}