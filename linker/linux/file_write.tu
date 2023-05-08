
use std
use linker.utils
use fmt
File::writeHeader(out) 
{
    utils.debug("File::writeHeader >",out)
    ehdr<Elf64_Ehdr> = this.ehdr
    bytes = 0

	fp = utils.fopen(out,"w+")
    bytes += int(ehdr.e_ehsize)

    utils.fwrite(fp,ehdr,ehdr.e_ehsize)

    if std.len(this.phdrTab) != 0 {  //程序头表
        for (phd : this.phdrTab) {
            bytes += int(ehdr.e_phentsize)
            utils.fwrite(fp,phd,ehdr.e_phentsize)
        }
    }
    utils.fclose(fp)
    utils.debug("File::writeHeader successfully :",bytes)
	return bytes
}

File::writeSecSym(out) 
{
    utils.debug("File::writeSecSym")
    bytes = 0
    ehdr<Elf64_Ehdr> = this.ehdr
    shstrtabSize<i32> = *this.shstrtabSize

    fp = utils.fopen(out,"a+")
    bytes += int(shstrtabSize)
    utils.fwrite(fp,this.shstrtab,shstrtabSize)
    for ( sn : this.shdrNames) {

		sh<Elf64_Shdr> = this.shdrTab[sn]
        bytes += int(ehdr.e_shentsize)
        utils.fwrite(fp,sh,ehdr.e_shentsize)
    }
    Elf64_Sym_Size<i8> = sizeof(Elf64_Sym)
    for (symname : this.symNames) {
		sym<Elf64_Sym> = this.symTab[symname]
        bytes += int(Elf64_Sym_Size)
        utils.fwrite(fp,sym,Elf64_Sym_Size)
    }
    bytes += this.shstrtabSize
    utils.fwrite(fp,this.strtab,shstrtabSize)
    utils.fclose(fp)
    return bytes
}

