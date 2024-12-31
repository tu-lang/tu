use asmer.asm
use asmer.ast
use asmer.utils
use std
use std.map
use string

mem RelInfo {
	string.String* tarSeg
	string.String* name
	i32			   offset
	i32			   type
}
RelInfo::init(seg<string.String> , addr<i32> ,name<string.String> , t<i32>){
	this.tarSeg = seg
	this.offset = addr
	this.name = name
	this.type = t
}


mem ElfFile
{
	i32  		offset
	Elf64_Ehdr  ehdr
	map.Map*    shdrTab // string:Elf64_Shdr
	map.Map*    strIndex //string:i32
	map.Map*    symTab //string:Elf64_Sym
	std.Array*	shdrNames//[string]
	std.Array*  symNames//[string]
	std.Array*  relTab//[RelInfo]
	std.Array*  relTextTab //[Elf64_Rela]
	std.Array*  relDataTab //[Elf64_Rela]

	i8*		shstrtab
	i8*		strtab
	i32 	shstrtab_size,strtab_size,sh_info
	asm.Asmer*  asmer
}
func mapstringhashkey(k<string.String>){
    return k.hash64()
}
ElfFile::init(ac<asm.Asmer>){
	utils.debug("ElfFile::init() ".(i8))
	this.asmer = ac
    this.offset = 0
	this.shstrtab = null
	this.strtab   = null
	//init map & arr
	this.shdrTab  =  map.map_new(mapstringhashkey.(u64),0.(i8))
	this.strIndex =  map.map_new(mapstringhashkey.(u64),0.(i8))
	this.symTab   =  map.map_new(mapstringhashkey.(u64),0.(i8))
	this.shdrNames = std.NewArray()
	this.symNames  = std.NewArray()
	this.relTab	   = std.NewArray()
	this.relTextTab = std.NewArray()
	this.relDataTab = std.NewArray()
	//default section
	this.addShdr(
		string.emptyS(),
		0.(i8),0.(i8),0.(i8),0.(i8),
		0.(i8),0.(i8),0.(i8),0.(i8),0.(i8)
	)
	this.addSym2(string.emptyS(),0.(i8))
}

