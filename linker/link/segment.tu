use linker.linux
use fmt
use linker.utils
use std
use std.map
use string

// Collected section contents and layout for one output segment.
mem Seglist {
	i32 baseAddr
	i32 offset
	i32 size
	i32 begin
	std.Array* ownerList // linux.File*
	std.Array* blocks    // Block*
}

Seglist::init(){
	this.baseAddr = 0
	this.offset = 0
	this.size = 0
	this.begin = 0
	this.ownerList = std.NewArray()
	this.blocks = std.NewArray()
}

// Layout owners into this segment; optionally grow .data for pclntab.
Seglist::allocAddr(
	name<string.String>, base<i32*>, off<i32*>, pclntabNeed<u32>
){
	utils.debug("Seglist::allocAddr %S %d".(i8), name.str(), *off)
	this.begin = *off
	if name.cmpstr(*".bss") != string.Equal {
		tmp<i32> = MEM_ALIGN - *base % MEM_ALIGN
		*base += tmp % MEM_ALIGN
	}
	align<i32> = DISC_ALIGN
	if name.cmpstr(*".text") == string.Equal {
		align = 16
	}
	temp_align<i32> = align - *off % align
	*off += temp_align % align

	*base = *base - *base % MEM_ALIGN + *off % MEM_ALIGN
	this.baseAddr = *base
	this.offset = *off
	size<i32> = 0
	need_i<i32> = pclntabNeed.(i32)
	i<i32> = 0
	while i < this.ownerList.len() {
		ts<i32> = DISC_ALIGN - size % DISC_ALIGN
		size += ts % DISC_ALIGN
		owner<linux.File> = this.ownerList.addr[i]
		seg<linux.Elf64_Shdr> = owner.shdrTab.find(name)
		file_sz<i32> = seg.sh_size.(i32)
		blk_sz<i32> = file_sz
		grow<i32> = 0
		if name.cmpstr(*".data") == string.Equal && need_i > 0 && need_i > file_sz {
			if owner.symTab.find(string.S(*"runtime_pclntab")) != map.Null {
				grow = 1
			}
		}
		if grow == 1 {
			blk_sz = need_i
			need_as_u64<u64> = need_i.(u64)
			seg.sh_size = need_as_u64
		}
		if name.cmpstr(*".bss") != string.Equal {
			if blk_sz != 0 {
				ss<i32> = blk_sz
				buf<u64*> = new ss
				zi<i32> = 0
				while zi < blk_sz {
					bp<i8*> = buf
					bp = bp + zi
					*bp = 0
					zi += 1
				}
				if file_sz != 0 {
					file_sz_u<u64> = file_sz.(u64)
					owner.getData(buf, seg.sh_offset, file_sz_u)
				}
				off_u32<u32> = size.(u32)
				sz_u32<u32> = blk_sz.(u32)
				this.blocks.push(newBlock(buf, off_u32, sz_u32))
			}
		}
		seg.sh_addr = *base + size
		size += blk_sz
		i += 1
	}
	*base = *base + size
	if name.cmpstr(*".bss") != string.Equal {
		*off += size
	}
	this.size = size
}

Seglist::relocAddr(relAddr<u32>, type<u8>, symAddr<u32>, addend<i32>){
	utils.debug("Seglist::relocAddr %d".(i8), this.baseAddr)

	baddr<u32> = this.baseAddr.(u32)
	relOffset<u32> = relAddr - baddr

	b<Block> = null
	i<i32> = 0
	while i < this.blocks.len() {
		v<Block> = this.blocks.addr[i]
		if v.offset <= relOffset && v.offset + v.size > relOffset {
			b = v
			break
		}
		i += 1
	}
	if b == null {
		utils.error("data reloction over offset")
	}
	base<i8*> = b.data
	paddr<i32*> = base + relOffset - b.offset

	match type {
		42 | linux.R_X86_64_GOTPCREL : {
			inst<u8*> = paddr
			inst -= 1
			modr<u8*> = inst
			inst -= 1
			opcode<u8*> = inst
			if *opcode == 0x8b {
				_reg<u8> = *modr - 0x05
				reg<u8> = _reg / 8
				*opcode = 0xc7
				*modr = 0xc0 + reg
			}
			*paddr = symAddr - addend
		}
		linux.R_X86_64_PC32  : *paddr = symAddr - relAddr + *paddr
		linux.R_X86_64_PLT32 : *paddr = symAddr - relAddr + *paddr
		linux.R_X86_64_64    : *paddr = symAddr - addend
		_                    : utils.debug("unknow rela".(i8))
	}
}

// Read u64 at VA into out; returns 1 on hit, 0 on miss.
Seglist::pcln_read_u64_into(va_u<u32>, out<u64*>) i32 {
	baddr_u<u32> = this.baseAddr.(u32)
	rel_u<u32> = va_u - baddr_u
	eight_u<u32> = 8
	i<i32> = 0
	while i < this.blocks.len() {
		v<Block> = this.blocks.addr[i]
		if v.offset <= rel_u && rel_u + eight_u <= v.offset + v.size {
			base<i8*> = v.data
			off_i<i32> = (rel_u - v.offset).(i32)
			p<u64*> = base + off_i
			*out = *p
			return 1
		}
		i += 1
	}
	return 0
}

// Read i32 at VA into out; returns 1 on hit, 0 on miss.
Seglist::pcln_read_i32_into(va_u<u32>, out<i32*>) i32 {
	baddr_u<u32> = this.baseAddr.(u32)
	rel_u<u32> = va_u - baddr_u
	four_u<u32> = 4
	i<i32> = 0
	while i < this.blocks.len() {
		v<Block> = this.blocks.addr[i]
		if v.offset <= rel_u && rel_u + four_u <= v.offset + v.size {
			base<i8*> = v.data
			off_i<i32> = (rel_u - v.offset).(i32)
			p<i32*> = base + off_i
			*out = *p
			return 1
		}
		i += 1
	}
	return 0
}
