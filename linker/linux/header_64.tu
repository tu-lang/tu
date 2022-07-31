

# u16 Elf32_Half;
# u16 Elf64_Half;
# u32 Elf32_Word;
# int32  Elf32_Sword;
# u32 Elf64_Word;
# int32  Elf64_Sword;

# u64 Elf32_Xword;
# int64  Elf32_Sxword;
# u64 Elf64_Xword;
# int64  Elf64_Sxword;

# u32 Elf32_Addr
# u64 Elf64_Addr
# u32 Elf32_Off;
# u64 Elf64_Off
# u16 Elf32_Section;
# u16 Elf64_Section; 
# u16 Elf32_Versym;
# u16 Elf64_Versym;

# 支持嵌套设Elf64_Ehdr计
# TODO: struct
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

# 程序头表
mem Elf64_Phdr
{
	u32 p_type
	u32 p_flags
	u64 p_offset
	u64 p_vaddr
	u64 p_paddr
	u64 p_filesz
	u64 p_memsz
	u64 p_align
}

# 段表
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

mem Elf64_Sym
{
	u32 st_name
	u8  st_info
	u8  st_other
	u16 st_shndx
	u64 st_value
	u64 st_size
}

mem Elf64_Rela
{
	u64 r_offset
	u64 r_info
	i64  r_addend
}