use fmt
use os
use std
use string

mem Elf64_Ehdr 
{
	u8  e_ident[16]
	u16 e_type
	u16 e_machine
	u32 e_version
	u64 e_entry
	u64 e_phoff
	u64 e_shoff
	u32 e_flags

	u16 e_ehsize
	u16 e_phentsize
	u16 e_phnum
	u16 e_shentsize
	u16 e_shnum
	u16 e_shstrndx
}

mem Elf64_Shdr
{
	u32 sh_name
	u32 sh_type
	u64 sh_flags
	u64 sh_addr
	u64 sh_offset
	u64 sh_size
	u32 sh_link
	u32 sh_info
	u64 sh_addralign
	u64 sh_entsize
}
mem Elf {
    u8* filepath
    u8* buffer
    i32 len 
    Elf64_Ehdr* eheader
}

Elf::init()
{
	if this.filepath == null error("filepath is null")

	fd<i32> = std.fopen(this.filepath,"r".(i8))
	if fd <= null error("open elf file failed")

	size<i64> = std.fseek(fd , Null , std.SEEK_END)
	std.fseek(fd,Null,std.SEEK_SET)
	//len
	this.len = size
	//last pos \0
	size += 1
	buf<u8*> = new size

	read_size<i64> = std.read(fd,buf,this.len)
	if read_size != this.len 
		error("fread err")
	this.buffer = buf

	if this.len < sizeof(Elf64_Ehdr) {
		error("too short")
	}
	this.eheader = buf
	if this.eheader.e_ident[EI_CLASS] != ELFCLASS64 {
		error("bad elf class ")
	}
	if this.eheader.e_ident[EI_DATA] != ELFDATA2LSB {
		error("bad elf data format")
	}
	if this.eheader.e_ident[EI_VERSION] != EV_CURRENT {
		error("bad elf version")
	}

}
Elf::Section(dst<i8*>) {
	sec<Elf64_Shdr> = this.buffer + this.eheader.e_shoff
	seccounts<i32>  = this.eheader.e_shnum
	
	secnames<Elf64_Shdr> = sec + this.eheader.e_shstrndx * sizeof(Elf64_Shdr)
	//TODO: names<u8*> = &this.buffer[secnames.sh_offset]
	names<u8*> = this.buffer + secnames.sh_offset

	for (i<i32> = 0 ; i < seccounts ;  i += 1) {
		//TODO: sec[i]
		shdr<Elf64_Shdr> = sec + i * sizeof(Elf64_Shdr)
		name<i8*> = names + shdr.sh_name
		if std.strcmp(name, dst) == Null
			return shdr
	}
	return Null
}