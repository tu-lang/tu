use fmt
use std
use std.map
use string
use linker.utils

fn mapstringhashkey(k<string.String>) u64 {
	return k.hash64()
}

// ELF object/executable file view used by the Linux linker.
mem File {
	Elf64_Ehdr* ehdr
	std.Array*  phdrTab   // Elf64_Phdr*
	map.Map*    shdrTab   // string.String* -> Elf64_Shdr*
	std.Array*  shdrNames // string.String*
	map.Map*    symTab    // string.String* -> Elf64_Sym*
	std.Array*  symNames  // string.String*
	std.Array*  symbols   // string.String*
	std.Array*  relTab    // RelItem*

	string.String* elfdir
	i8*  shstrtab
	i32  shstrtabsize
	i8*  strtab
	i32  strtabsize
}

File::init(){
	this.ehdr = new Elf64_Ehdr
	this.phdrTab = std.NewArray()
	this.shdrTab = map.map_new(mapstringhashkey.(u64), 0.(i8))
	this.shdrNames = std.NewArray()
	this.symTab = map.map_new(mapstringhashkey.(u64), 0.(i8))
	this.symNames = std.NewArray()
	this.symbols = std.NewArray()
	this.relTab = std.NewArray()
	this.elfdir = null
	this.shstrtab = null
	this.shstrtabsize = 0
	this.strtab = null
	this.strtabsize = 0
}

File::addPhdr(
	type<u32>, off<u64>, vaddr<u64>, filesz<u64>, memsz<u64>,
	flags<u32>, align<u64>
){
	utils.debug("File::addPhdr".(i8))
	ph<Elf64_Phdr> = new Elf64_Phdr
	ph.p_type = type
	ph.p_offset = off
	ph.p_vaddr = vaddr
	ph.p_paddr = vaddr
	ph.p_filesz = filesz
	ph.p_memsz = memsz
	ph.p_flags = flags
	ph.p_align = align
	this.phdrTab.push(ph)
}

File::addShdr(
	sh_name<string.String>,
	sh_type<u32>, sh_flags<u64>, sh_addr<u64>, sh_offset<u64>,
	sh_size<u64>, sh_link<u32>, sh_info<u32>, sh_addralign<u64>,
	sh_entsize<u64>
){
	utils.debug("File::addShdr %S".(i8), sh_name.str())
	sh<Elf64_Shdr> = new Elf64_Shdr
	sh.sh_name = 0
	sh.sh_type = sh_type
	sh.sh_flags = sh_flags
	sh.sh_addr = sh_addr
	sh.sh_offset = sh_offset
	sh.sh_size = sh_size
	sh.sh_link = sh_link
	sh.sh_info = sh_info
	sh.sh_addralign = sh_addralign
	sh.sh_entsize = sh_entsize
	this.shdrTab.insert(sh_name, sh)
	this.shdrNames.push(sh_name)
}

File::addSym(st_name<string.String>, s<Elf64_Sym>){
	utils.debug("File::addSym %S".(i8), st_name.str())
	sym<Elf64_Sym> = new Elf64_Sym
	this.symTab.insert(st_name, sym)
	if st_name.empty() == string.True {
		sym.st_name = 0
		sym.st_value = 0
		sym.st_size = 0
		sym.st_info = 0
		sym.st_other = 0
		sym.st_shndx = 0
	} else {
		sym.st_name = 0
		sym.st_value = s.st_value
		sym.st_size = s.st_size
		sym.st_info = s.st_info
		sym.st_other = s.st_other
		sym.st_shndx = s.st_shndx
	}
	this.symNames.push(st_name)
}
