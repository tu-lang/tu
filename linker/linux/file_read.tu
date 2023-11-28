
use os
use fmt
use linker.utils
use string
use std
File::readElf(file)
{
	utils.debug("Reading elf object info " ,file)
	this.elfdir = file

	fp<i32> = utils.fopen(file,"rb")
	if fp <= 0  {
		utils.error("can't open file, file invalid:" + file)
	}
	utils.rewind(fp)

	ehdr<Elf64_Ehdr> = utils.fread(fp,sizeof(Elf64_Ehdr))
	if ehdr.e_type == ET_EXEC {
		utils.fseek(fp,ehdr.e_phoff)
		for(i<i32> = 0 ; i < ehdr.e_phnum; i += 1){
			phdr<Elf64_Phdr> = utils.fread(fp,sizeof(Elf64_Phdr))
			this.phdrTab[] = phdr
		}
	}
	utils.fseek(fp,ehdr.e_shoff + ehdr.e_shentsize * ehdr.e_shstrndx)
	shstrTab<Elf64_Shdr> = utils.fread(fp,sizeof(Elf64_Shdr))
	utils.fseek(fp,shstrTab.sh_offset)
	shstrTabData<i8*> = utils.fread(fp,shstrTab.sh_size)
	utils.debug("字符串表:",string.new(shstrTabData))

	utils.fseek(fp,ehdr.e_shoff)
	for(i<i32> = 0 ; i < ehdr.e_shnum ; i += 1){
		shdr<Elf64_Shdr> = utils.fread(fp,sizeof(Elf64_Shdr))
		name = string.new(shstrTabData + shdr.sh_name)
		//utils.debug("read section.name:", name)
		this.shdrNames[] = name
		# map映射
		if name != "" {
			this.shdrTab[name] = shdr
		}
	}
	//utils.debug(this.shdrTab)
	strTab<Elf64_Shdr> = this.shdrTab[".strtab"]
	utils.fseek(fp,strTab.sh_offset)
	strTabData<i8*> = utils.fread(fp,strTab.sh_size)


	sh_symTab<Elf64_Shdr> = this.shdrTab[".symtab"]
	utils.fseek(fp,sh_symTab.sh_offset)
	symNum<i32> = sh_symTab.sh_size / sh_symTab.sh_entsize

	symList = []
	utils.debug("total sym num:",int(symNum))
	for(i<i32> = 0 ; i < symNum ; i += 1){
		sym<Elf64_Sym> = utils.fread(fp,sizeof(Elf64_Sym))
		symList[] = sym
		name = string.new(strTabData + sym.st_name)		
		utils.debug("read symbols table.name:", name)
		this.symbols[] = name

		if  name == "_GLOBAL_OFFSET_TABLE_" {
			continue
		}
		if  name != "" {
			this.symTab[name] = sym
			continue
		}
		if  sym.st_shndx != SHN_UNDEF && sym.st_name == 0 {
			name = this.shdrNames[int(sym.st_shndx)]
			utils.debug("read symbols table.name: " ,name)
			if  name != "" {
				this.symTab[name] = sym
			}
		}
	}
	utils.debug(file,"relocation addr",std.len(symList))
	for( k,v : this.shdrTab ){
		if  k == ".rela.text" || k == ".rela.data" {
			relTab<Elf64_Shdr> = v
			utils.fseek(fp,relTab.sh_offset)
			relNum<i32> = relTab.sh_size / sizeof(Elf64_Rela)
			for(j<i32> = 0 ; j < relNum ; j += 1){
				rela<Elf64_Rela> = utils.fread(fp,sizeof(Elf64_Rela))
				//utils.debug("symList index:",int(ELF64_R_SYM(rela.r_info)))
				sym<Elf64_Sym> = symList[int(ELF64_R_SYM(rela.r_info))]
				index<i32>          = sym.st_name
				name = string.new(strTabData + index)
				//utils.debug("name:",name,int(j),int(relNum),int(index))
				if name == ""{
					if sym.st_shndx != SHN_UNDEF
						name = this.shdrNames[int(sym.st_shndx)]
				}
				this.relTab[] = new RelItem(string.sub(k,5),rela,name)
			} 
		}
	}
	utils.fclose(fp)
}

File::getSymIndex(symname)
{
	index = 0
	for i : this.symNames {
		if i == symname break
		index += 1
	}
	return index
}

File::getSegIndex(segname)
{
	//utils.debug("File::getSegIndex",segname,this.shdrNames)
	index = 0
	sl = std.len(this.shdrNames)
	for(i,v : this.shdrNames){
		if v == segname {
			return i
		}
	}
	utils.debug("can't get seg index by:",segname)
	return 0
}

File::getData(buf,offset,size)
{
	//utils.debug("File::getData ",elfdir)
	fp = utils.fopen(this.elfdir,"rb")
	utils.fseek(fp,offset)
	utils.fread_with_buf(fp,buf,size)
	utils.fclose(fp)
}	
