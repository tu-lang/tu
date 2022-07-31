use std
use fmt
use os
use linux

Linker::buildExe()
{
	utils.msg(90,"Building executable binary")
	exe = this.exe

	ehdr<linux.Elf64_Ehdr> = exe.ehdr
	#  获取变量的地址
	pid<i32*> = &ehdr.e_ident
	*pid  = 0x464c457f
	pid += 4
	*pid = 0x010102
	pid += 4
	*pid = 0
	pid += 4
	*pid = 0

	ehdr.e_type = linux.ET_EXEC
	ehdr.e_machine = linux.EM_X86_64
	ehdr.e_version = linux.EV_CURRENT
	ehdr.e_flags = 0
	ehdr.e_ehsize = sizeof(linux.Elf64_Ehdr)

	#curOff = sizeof(linux.Elf64_Ehdr) + sizeof(linux.Elf64_Phdr) * std.len(this.segNames)
	curOff = int(sizeof(linux.Elf64_Ehdr)) + int(sizeof(linux.Elf64_Phdr)) * std.len(this.segNames)
	# 空段表
	zero = 0
	exe.addShdr("",zero,zero,zero,zero,zero,zero,zero,zero,zero)

	shstrtabSize = 26
	for(seg : this.segNames){
		# 每个字符串末尾自动加上结束符号 \0
		shstrtabSize += std.len(seg) + 1

		flags<i32> = linux.PF_W | linux.PF_R
		filesz = this.segLists[seg].size
		if  seg == ".text" {
			flags = linux.PF_X | linux.PF_R
		}
		if  seg == ".bss"  {
			filesz = 0
		}
		# 添加程序头表
		exe.addPhdr(int(linux.PT_LOAD),
			this.segLists[seg].offset,
			this.segLists[seg].baseAddr,
			filesz,
			this.segLists[seg].size,
			int(flags),
			int(MEM_ALIGN)
		)
		# 计算有效数据段的大小和偏移
		curOff = this.segLists[seg].offset
		#生成段表项
		sh_type = int(linux.SHT_PROGBITS)
		sh_flags<i32> = linux.SHF_ALLOC | linux.SHF_WRITE
		sh_align = 4
		if  seg == ".bss" {
			sh_type = int(linux.SHT_NOBITS)
		}
		if  seg == ".text" {
			sh_flags = linux.SHF_ALLOC | linux.SHF_EXECINSTR
			sh_align = 16
		}
	}
	ehdr.e_phoff = sizeof(linux.Elf64_Ehdr)
	ehdr.e_phentsize = sizeof(linux.Elf64_Phdr)
	segnames_len = std.len(segNames)
	ehdr.e_phnum = *segnames_len

	ehdr.e_shentsize = sizeof(linux.Elf64_Shdr)
	start<linux.Elf64_Sym> = this.symDef["main"].prov.symTab["main"]
	ehdr.e_entry = start.st_value
	//no need keep write strtab ... sort or things;
	return true
}

Linker::writeExe(out)
{
	utils.msg(100,"Generating executable binary")
	exe = this.exe
    ehdr<linux.Elf64_Ehdr> = exe.ehdr
	offset = exe.writeHeader(out)
	slen = int(sizeof(linux.Elf64_Ehdr)) + std.len(exe.phdrTab) * int(sizeof(linux.Elf64_Phdr))
	fmt.assert(offset,slen,"Linker::writeExe")
	fp = utils.fopen(out,"a+")
	pad<i8*> = 0
	one<i8> = 1
	for(seg : this.segNames){
		sl = this.segLists[seg]
		padnum = sl.offset - sl.begin
		offset += padnum
		while padnum {
			padnum -= 1
			utils.fwrite(fp,&pad,one)
		}
		#输出
		if  seg != ".bss" {
			old<Block> = null
			instPad<i8*> = 0x90
			for(b<Block> : sl.blocks){
				if  old != null {

					padnum1<i32> = b.offset - old.offset - old.size
					offset += int(padnum1)
					while padnum1 {
						padnum1 -= 1
						utils.fwrite(fp,&instPad,one)
					}
				}
				old = b
				offset += int(b.size)
				utils.fwrite(fp,b.data,b.size)
			}
		}
	}
	utils.fclose(fp)
	return true
}

Linker::link(out)
{
	utils.debug("Linker::link")
	this.collectInfo()
	if   !this.symValid() {
		return false
	}
	this.allocAddr()
	this.symParser()
	this.relocate()
	this.buildExe()
	this.writeExe(out)
	return true
}