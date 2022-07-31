
use std
use utils
use fmt
# 写入header头
# 写入程序表头
File::writeHeader(out) 
{
    utils.debug("File::writeHeader >",out)
    ehdr<Elf64_Ehdr> = this.ehdr
    bytes = 0

	fp = utils.fopen(out,"w+")
    bytes += int(ehdr.e_ehsize)

	# elf文件头
    utils.fwrite(fp,ehdr,ehdr.e_ehsize)

    if std.len(phdrTab) != 0 {  //程序头表
        for (phd : phdrTab) {
            bytes += int(ehdr.e_phentsize)
			# 写入程序表头
            utils.fwrite(fp,phd,ehdr.e_phentsize)
        }
    }
    utils.fclose(fp)
    utils.debug("File::writeHeader successfully :",bytes)
	return bytes
}

# 1. 写入段表 + 段字符串表
# 2. 写入符号表 + 符号字符串表
File::writeSecSym(out) 
{
    utils.debug("File::writeSecSym")
    bytes = 0
    ehdr<Elf64_Ehdr> = this.ehdr
    shstrtabSize<i32> = *this.shstrtabSize

    fp = utils.fopen(out,"a+")
    bytes += int(shstrtabSize)
    #字符串段表: 写入所有关于段名的字符串 .shstrtab
    utils.fwrite(fp,this.shstrtab,shstrtabSize)
    #段表: 写入所有段
    for ( sn : this.shdrNames) {

		sh<Elf64_Shdr> = this.shdrTab[sn]
        bytes += int(ehdr.e_shentsize)
        utils.fwrite(fp,sh,ehdr.e_shentsize)
    }
    #符号表: 写入所有符号
    Elf64_Sym_Size<i8> = sizeof(Elf64_Sym)
    for (symname : this.symNames) {
		sym<Elf64_Sym> = this.symTab[symname]
        bytes += int(Elf64_Sym_Size)
        utils.fwrite(fp,sym,Elf64_Sym_Size)
    }
    # 字符串表: 写入所有字符串
    bytes += this.shstrtabSize
    utils.fwrite(fp,strtab,shstrtabSize)
    utils.fclose(fp)
    return bytes
}

