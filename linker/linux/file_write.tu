use std
use linker.utils
use fmt
use string

File::writeHeader(path<string.String>) i32 {
	utils.debug("File::writeHeader".(i8))
	ehdr<Elf64_Ehdr> = this.ehdr
	bytes<i32> = 0

	fp<i32> = std.fopen(path.str(), *"w+")
	if fp <= 0 {
		utils.error("writeHeader fopen failed")
	}
	bytes += ehdr.e_ehsize.(i32)

	utils.fwrite(fp, ehdr, ehdr.e_ehsize.(u64))

	if this.phdrTab.len() != 0 {
		i<i32> = 0
		while i < this.phdrTab.len() {
			phd<Elf64_Phdr> = this.phdrTab.addr[i]
			bytes += ehdr.e_phentsize.(i32)
			utils.fwrite(fp, phd, ehdr.e_phentsize.(u64))
			i += 1
		}
	}
	utils.fclose(fp)
	utils.debug("File::writeHeader successfully".(i8))
	return bytes
}

File::writeSecSym(path<string.String>) i32 {
	utils.debug("File::writeSecSym".(i8))
	bytes<i32> = 0
	ehdr<Elf64_Ehdr> = this.ehdr
	shstrtabSize<i32> = this.shstrtabsize

	fp<i32> = std.fopen(path.str(), *"a+")
	if fp <= 0 {
		utils.error("writeSecSym fopen failed")
	}
	bytes += shstrtabSize
	utils.fwrite(fp, this.shstrtab, shstrtabSize.(u64))
	i<i32> = 0
	while i < this.shdrNames.used {
		sn<string.String> = this.shdrNames.addr[i]
		sh<Elf64_Shdr> = this.shdrTab.find(sn)
		bytes += ehdr.e_shentsize.(i32)
		utils.fwrite(fp, sh, ehdr.e_shentsize.(u64))
		i += 1
	}
	j<i32> = 0
	while j < this.symNames.used {
		symname<string.String> = this.symNames.addr[j]
		sym<Elf64_Sym> = this.symTab.find(symname)
		bytes += ELF64_SYM_SIZE
		utils.fwrite(fp, sym, ELF64_SYM_SIZE.(u64))
		j += 1
	}
	bytes += this.shstrtabsize
	utils.fwrite(fp, this.strtab, shstrtabSize.(u64))
	utils.fclose(fp)
	return bytes
}
