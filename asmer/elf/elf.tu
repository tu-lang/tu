use asmer.ast
use asmer.utils
use std
use string
use fmt

ElfFile::getSegIndex(segName<string.String>)
{
	index<i32> = 0
	for i<i32> = 0; i < this.shdrNames.len(); i += 1 {
		if segName.cmp(this.shdrNames.addr[i]) == string.Equal 
			break
		index += 1
	}
	return index
}
ElfFile::getSymIndex(symName<string.String>)
{
	index<i32> = 0
	for i<i32> = 0;i < this.symNames.len(); i += 1 {
		if symName.cmp(this.symNames.addr[i]) == string.Equal 
			break
		index += 1
	}
	return index
}

ElfFile::addTDShdr(sh_name<string.String>,size<i32>)
{
	utils.debug("ElfFile::addTDShdr() %S %d".(i8),sh_name.str(),size)
	if sh_name.cmpstr(*".text") == string.Equal
	{
		this.addShdr(
			sh_name,SHT_PROGBITS,
			SHF_ALLOC|SHF_EXECINSTR,0.(i8),
			this.offset,size,0.(i8),0.(i8),1.(i8),0.(i8)
		)
	}
	else if sh_name.cmpstr(*".data") == string.Equal
	{
		this.addShdr(
			sh_name,SHT_PROGBITS,
			SHF_ALLOC|SHF_WRITE,0.(i8),this.offset,size,
			0.(i8),0.(i8),1.(i8),0.(i8)
		)
	}
}
// @param sh_name
// @param sh_type
// @param sh_flags
// @param sh_addr
// @param sh_offset
// @param sh_size
// @param sh_link
// @param sh_info
// @param sh_addralign
// @param sh_entsize
ElfFile::addShdr(
	sh_name<string.String>,	sh_type<u32>,	sh_flags<u32>,	sh_addr<u64>,
	sh_offset<u64>,	sh_size<u32>,	sh_link<u32>,	sh_info<u32>, sh_addralign<u32>,
	sh_entsize<u32>)
{
	utils.debug("ElfFile::addShdr() %S".(i8),sh_name.str())
	sh<Elf64_Shdr>    = new Elf64_Shdr{
		sh_name   	 : 0,
		sh_type      : sh_type,
		sh_flags     : sh_flags,
		sh_addr      : sh_addr,
		sh_offset    : sh_offset,
		sh_size      : sh_size,
		sh_link      : sh_link,
		sh_info      : sh_info,
		sh_addralign : sh_addralign,
		sh_entsize   : sh_entsize,
	}
	this.shdrTab.insert(sh_name ,sh)
	this.shdrNames.push(sh_name)
}
ElfFile::addSectionSym() {
	elfsym<Elf64_Sym> = new Elf64_Sym{
		st_name   : 0,
		st_value  : 0,
		st_size   : 0,
		st_info   : ELF64_ST_INFO(STB_LOCAL,STT_SECTION),
		st_other  : 0,
		st_shndx  : this.getSegIndex(string.S(*".text")),
	}
	this.addSym2(string.S(*".text"),elfsym)
	elfsym.st_shndx = this.getSegIndex(string.S(*".data"))
	this.addSym2(string.S(*".data"),elfsym)
}
ElfFile::addSym(sym<ast.Sym>)
{
	utils.debug("ElfFile::addSym() %S".(i8),sym.name.str())
	name<string.String>  = sym.name
	elfsym<Elf64_Sym> 	 = new Elf64_Sym{}
	elfsym.st_name   	 = 0
	elfsym.st_value  	 = sym.addr
	elfsym.st_size   	 = 0
	if sym.global || sym.externed
		elfsym.st_info  = ELF64_ST_INFO(STB_GLOBAL,STT_NOTYPE)
	else
		elfsym.st_info  = ELF64_ST_INFO(STB_LOCAL,STT_NOTYPE)

	elfsym.st_other     = 0
	if sym.externed {
		elfsym.st_shndx = STN_UNDEF
	}else{
		elfsym.st_shndx = this.getSegIndex(sym.segName)
	}
	utils.debug(*"symbol:%s section:%d ",sym.name.str(),sym.segName.str())
	this.addSym2(name,elfsym)
}
ElfFile::addSym2(st_name<string.String>,s<Elf64_Sym>)
{
	utils.debug("ElfFile::addSym2() %S ".(i8),st_name.str())
	sym<Elf64_Sym> = new Elf64_Sym
	this.symTab.insert(st_name , sym)
	
	if st_name.empty() == string.True {
		sym.st_name  = 0
		sym.st_value = 0
		sym.st_size  = 0
		sym.st_info  = 0
		sym.st_other = 0
		sym.st_shndx = 0
	}else{
		sym.st_name  = 0
		sym.st_value = s.st_value
		sym.st_size  = s.st_size
		sym.st_info  = s.st_info
		sym.st_other = s.st_other
		sym.st_shndx = s.st_shndx
	}
	this.symNames.push(st_name)
}
ElfFile::sortGlobal()
{
	utils.debug("ElfFile::sortGlobal()".(i8))
	global<std.Array> = std.NewArray()
	local<std.Array>  = std.NewArray()
	for(i<i32> = 0 ; i < this.symNames.len() ; i += 1){
		str<string.String> = this.symNames.addr[i]
		sym<Elf64_Sym> = this.symTab.find(str)
		if sym.st_info == ELF64_ST_INFO(STB_GLOBAL,STT_NOTYPE) {
			global.push(str)
		}else{
			local.push(str)
		}
	}
	//clear
	this.symNames = std.NewArray()
	for(i<i32> = 0 ; i < local.len() ; i += 1)
		this.symNames.push(local.addr[i])
	//first index
	this.sh_info = local.len()
	for(i<i32> = 0 ; i < global.len() ; i += 1)
		this.symNames.push(global.addr[i])
}
ElfFile::addRel(seg<string.String>,addr<i32>,name<string.String>,type<i32>)
{
	utils.debug("ElfFIle::addRel() %S %S".(i8),seg.str(),name.str())
	if name.empty() == string.True {
		utils.error("add empty rel")
	}
	rel<RelInfo> = new RelInfo(seg,addr,name,type)
	this.relTab.push(rel)
	return rel
}
