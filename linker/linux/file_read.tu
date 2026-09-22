use os
use fmt
use linker.utils
use string
use std
use std.map
use runtime

// Convert dyn string (from main / export facades) to string.String*.
fn file_path_from_dyn(obj) string.String {
	path<string.String> = null
	unsafe {
		sv<runtime.Value> = obj
		if sv != null {
			path = string.S(sv.data)
		}
	}
	return path
}

File::readElf(path<string.String>){
	utils.debug("Reading elf object info".(i8))
	this.elfdir = path

	fp<i32> = std.fopen(path.str(), *"rb")
	if fp <= 0 {
		utils.error("can't open file, file invalid")
	}
	utils.rewind(fp)

	ehdr<Elf64_Ehdr> = utils.fread(fp, ELF64_EHDR_SIZE.(u64))
	this.ehdr = ehdr
	if ehdr.e_type == ET_EXEC {
		utils.fseek(fp, ehdr.e_phoff)
		i<i32> = 0
		while i < ehdr.e_phnum {
			phdr<Elf64_Phdr> = utils.fread(fp, ELF64_PHDR_SIZE.(u64))
			this.phdrTab.push(phdr)
			i += 1
		}
	}
	utils.fseek(fp, ehdr.e_shoff + ehdr.e_shentsize * ehdr.e_shstrndx)
	shstrTab<Elf64_Shdr> = utils.fread(fp, ELF64_SHDR_SIZE.(u64))
	utils.fseek(fp, shstrTab.sh_offset)
	shstrTabData<i8*> = utils.fread(fp, shstrTab.sh_size)

	utils.fseek(fp, ehdr.e_shoff)
	i2<i32> = 0
	while i2 < ehdr.e_shnum {
		shdr<Elf64_Shdr> = utils.fread(fp, ELF64_SHDR_SIZE.(u64))
		name<string.String> = string.S(shstrTabData + shdr.sh_name)
		this.shdrNames.push(name)
		if name.empty() != string.True {
			this.shdrTab.insert(name, shdr)
		}
		i2 += 1
	}

	strTab<Elf64_Shdr> = this.shdrTab.find(string.S(*".strtab"))
	utils.fseek(fp, strTab.sh_offset)
	strTabData<i8*> = utils.fread(fp, strTab.sh_size)

	sh_symTab<Elf64_Shdr> = this.shdrTab.find(string.S(*".symtab"))
	utils.fseek(fp, sh_symTab.sh_offset)
	symNum<i32> = (sh_symTab.sh_size / sh_symTab.sh_entsize).(i32)

	symList<std.Array> = std.NewArray()
	utils.debug("total sym num".(i8))
	i3<i32> = 0
	while i3 < symNum {
		sym<Elf64_Sym> = utils.fread(fp, ELF64_SYM_SIZE.(u64))
		symList.push(sym)
		name2<string.String> = string.S(strTabData + sym.st_name)
		this.symbols.push(name2)

		if name2.cmpstr(*"_GLOBAL_OFFSET_TABLE_") == string.Equal {
			i3 += 1
			continue
		}
		if name2.empty() != string.True {
			this.symTab.insert(name2, sym)
			i3 += 1
			continue
		}
		if sym.st_shndx != SHN_UNDEF && sym.st_name == 0 {
			shndx3<i32> = sym.st_shndx.(i32)
			name3<string.String> = this.shdrNames.addr[shndx3]
			if name3.empty() != string.True {
				this.symTab.insert(name3, sym)
			}
		}
		i3 += 1
	}

	iter<map.MapIter> = this.shdrTab.iter()
	while iter.next() != map.End {
		k<string.String> = iter.k()
		v<Elf64_Shdr> = iter.v()
		if k.cmpstr(*".rela.text") == string.Equal || k.cmpstr(*".rela.data") == string.Equal {
			relTab<Elf64_Shdr> = v
			utils.fseek(fp, relTab.sh_offset)
			relNum<i32> = (relTab.sh_size / ELF64_RELA_SIZE.(u64)).(i32)
			j<i32> = 0
			while j < relNum {
				rela<Elf64_Rela> = utils.fread(fp, ELF64_RELA_SIZE.(u64))
				rinfo<u64> = rela.r_info
				symi<i32> = (rinfo >> 32).(i32)
				sym4<Elf64_Sym> = symList.addr[symi]
				index<i32> = sym4.st_name.(i32)
				rname<string.String> = string.S(strTabData + index)
				if rname.empty() == string.True {
					if sym4.st_shndx != SHN_UNDEF {
						shndx4<i32> = sym4.st_shndx.(i32)
						rname = this.shdrNames.addr[shndx4]
					}
				}
				klen<i32> = k.len()
				segname<string.String> = k.sub(5, klen - 5)
				this.relTab.push(new RelItem(segname, rela, rname))
				j += 1
			}
		}
	}
	utils.fclose(fp)
}

File::getSymIndex(symname<string.String>) i32 {
	index<i32> = 0
	i<i32> = 0
	while i < this.symNames.used {
		sn<string.String> = this.symNames.addr[i]
		if sn.cmp(symname) == string.Equal {
			break
		}
		index += 1
		i += 1
	}
	return index
}

File::getSegIndex(segname<string.String>) i32 {
	i<i32> = 0
	while i < this.shdrNames.used {
		v<string.String> = this.shdrNames.addr[i]
		if v.cmp(segname) == string.Equal {
			return i
		}
		i += 1
	}
	utils.debug("can't get seg index".(i8))
	return 0
}

File::getData(buf<i8*>, offset<u64>, size<u64>){
	fp<i32> = std.fopen(this.elfdir.str(), *"rb")
	utils.fseek(fp, offset)
	utils.fread_with_buf(fp, buf, size.(i64))
	utils.fclose(fp)
}
