use std
use fmt
use os
use linker.linux
use linker.utils
use string

// Fill ET_EXEC headers and program headers from collected segments.
Linker::buildExe() i32 {
	utils.msg(90, "Building executable binary")
	exe<linux.File> = this.exe

	ehdr<linux.Elf64_Ehdr> = exe.ehdr
	pid<i32*> = &ehdr.e_ident
	*pid = 0x464c457f
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
	ehdr.e_ehsize = linux.ELF64_EHDR_SIZE

	zero_u32<u32> = 0
	zero_u64<u64> = 0
	exe.addShdr(
		string.emptyS(),
		zero_u32, zero_u64, zero_u64, zero_u64,
		zero_u64, zero_u32, zero_u32, zero_u64, zero_u64
	)

	si<i32> = 0
	while si < this.segNames.len() {
		seg<string.String> = this.segNames.addr[si]
		sl<Seglist> = this.segLists.find(seg)

		flags<u32> = (linux.PF_W | linux.PF_R).(u32)
		filesz<u64> = sl.size.(u64)
		if seg.cmpstr(*".text") == string.Equal {
			flags = (linux.PF_X | linux.PF_R).(u32)
		}
		if seg.cmpstr(*".bss") == string.Equal {
			filesz = 0
		}
		exe.addPhdr(
			linux.PT_LOAD.(u32),
			sl.offset.(u64),
			sl.baseAddr.(u64),
			filesz,
			sl.size.(u64),
			flags,
			MEM_ALIGN.(u64)
		)
		si += 1
	}
	ehdr.e_phoff = linux.ELF64_EHDR_SIZE.(u64)
	ehdr.e_phentsize = linux.ELF64_PHDR_SIZE
	ehdr.e_phnum = this.segNames.len().(u16)

	ehdr.e_shentsize = linux.ELF64_SHDR_SIZE
	main_sl<SymLink> = this.symDef.find(string.S(*"main"))
	start<linux.Elf64_Sym> = main_sl.prov.symTab.find(string.S(*"main"))
	ehdr.e_entry = start.st_value
	return 1
}

// Write ELF image to path.
Linker::writeExe(path<string.String>) i32 {
	utils.msg(100, "Generating executable binary")
	exe<linux.File> = this.exe
	offset<i32> = exe.writeHeader(path)
	slen<i32> = linux.ELF64_EHDR_SIZE + this.exe.phdrTab.len().(i32) * linux.ELF64_PHDR_SIZE
	if offset != slen {
		os.die("Linker::writeExe header size mismatch")
	}

	fp<i32> = std.fopen(path.str(), *"a+")
	if fp <= 0 {
		os.die("writeExe fopen failed")
	}
	zero_b<i8> = 0
	nop_b<i8> = 0x90
	one_u<u64> = 1
	si<i32> = 0
	while si < this.segNames.len() {
		seg<string.String> = this.segNames.addr[si]
		sl<Seglist> = this.segLists.find(seg)
		padnum<i32> = sl.offset - sl.begin
		if padnum < 0 {
			os.die("writeExe negative segment pad")
		}
		offset += padnum
		while padnum > 0 {
			padnum -= 1
			utils.fwrite(fp, &zero_b, one_u)
		}
		is_bss<i32> = seg.cmpstr(*".bss")
		if is_bss != string.Equal {
			old<Block> = null
			have_old<i32> = 0
			bi<i32> = 0
			blen<i32> = sl.blocks.len().(i32)
			while bi < blen {
				b<Block> = sl.blocks.addr[bi]
				if have_old == 1 {
					padnum1<i32> = (b.offset - old.offset - old.size).(i32)
					if padnum1 < 0 {
						os.die("writeExe negative block pad")
					}
					offset += padnum1
					while padnum1 > 0 {
						padnum1 -= 1
						utils.fwrite(fp, &nop_b, one_u)
					}
				}
				old = b
				have_old = 1
				offset += b.size.(i32)
				bsz<u64> = b.size.(u64)
				if bsz != 0 {
					if b.data == null {
						os.die("writeExe null block data")
					}
					utils.fwrite(fp, b.data, bsz)
				}
				bi += 1
			}
		}
		si += 1
	}
	utils.fclose(fp)
	return 1
}

Linker::link(path<string.String>) i32 {
	utils.debug("Linker::link".(i8))
	this.collectInfo()
	if this.symValid() == 0 {
		return 0
	}
	this.allocAddr()
	this.symParser()
	this.fixPclntabEnd()
	this.relocate()
	this.fillPclntab()
	this.buildExe()
	this.writeExe(path)
	return 1
}
