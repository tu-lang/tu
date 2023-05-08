use fmt

class File {
    ehdr   = new Elf64_Ehdr     # Elf64_Ehdr elf头
	# char *buf,Elf64_Off offset,Elf64_Word size)
	phdrTab = []    # Elf64_Phdr
	shdrTab = {}    # Elf64_Shdr
	shdrNames = []  # array[]
	symTab  = {}    # Elf64_Sym
	symNames = []   # array[]
	symbols = []    # string name
	relTab = []     # Elf64_Rela

    elfdir      # file path
    shstrtab    # char* str
    shstrtabsize# size
    strtab      # char* str
    strtabsize  # size
}


File::addPhdr(type,off,vaddr,filesz,memsz,flags,align)
{
    utils.debug("File::addPhdr")
	ph<Elf64_Phdr> = new Elf64_Phdr
	ph.p_type = *type	
	ph.p_offset = *off
	ph.p_vaddr = *vaddr
	ph.p_paddr = *vaddr
	ph.p_filesz = *filesz
	ph.p_memsz = *memsz
	ph.p_flags = *flags
	ph.p_align = *align
	
	this.phdrTab[] = ph
}
File::addShdr(sh_name,sh_type,sh_flags,sh_addr,sh_offset,sh_size,sh_link,sh_info,sh_addralign,sh_entsize)
{
    utils.debug("File::addShdr",sh_name)
    sh<Elf64_Shdr>    = new Elf64_Shdr

    sh.sh_name      = 0
    sh.sh_type      = *sh_type
    sh.sh_flags     = *sh_flags
    sh.sh_addr      = *sh_addr
    sh.sh_offset    = *sh_offset
    sh.sh_size     = *sh_size
    sh.sh_link      = *sh_link
    sh.sh_info      = *sh_info
    sh.sh_addralign = *sh_addralign
    sh.sh_entsize   = *sh_entsize


    this.shdrTab[sh_name] = sh
    this.shdrNames[] = sh_name
}
File::addSym(st_name,s<Elf64_Sym>)
{
    utils.debug("File::addSym",st_name)
    sym<Elf64_Sym>    = new Elf64_Sym
    this.symTab[st_name]   = sym
    if st_name == "" {
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
	this.symNames[] = st_name
}