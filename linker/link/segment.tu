use linker.linux
use fmt
use linker.utils

class Seglist
{
	baseAddr  = 0   // base addr
	offset    = 0   // finally offset
	size	  = 0   // finally size
	begin  	  = 0   // start address
	ownerList = []  // array[ElfFile] 
	blocks	  = []  // array[Block]
}

// @param name
// @param off
// @param base
// @param pclntabNeed grow runtime_pclntab owner .data to exact need (0 = no grow)
Seglist::allocAddr(name,base<i32*>,off<i32*>,pclntabNeed<u32>)
{
	utils.debug("Seglist::allocAddr ",name,int(*off))
	this.begin = int(*off) 
	if  name != ".bss" {
		tmp<i32> = MEM_ALIGN - *base % MEM_ALIGN
		*base += tmp % MEM_ALIGN
	}
	align<i32> = DISC_ALIGN
	if  name == ".text" {
		align = 16
	}
	temp_align<i32> = align - *off % align
	*off += temp_align % align

	*base = *base - *base % MEM_ALIGN + *off % MEM_ALIGN
	this.baseAddr = int(*base)
	this.offset = int(*off)
	size<i32> = 0
	need_i<i32> = pclntabNeed.(i32)
	for( i = 0 ; i < std.len(this.ownerList) ; i += 1){
		ts<i32> = DISC_ALIGN - size % DISC_ALIGN
		size += ts % DISC_ALIGN
		seg<linux.Elf64_Shdr> = this.ownerList[i].shdrTab[name]
		file_sz<i32> = seg.sh_size.(i32)
		blk_sz<i32> = file_sz
		owner = this.ownerList[i]
		grow<i32> = 0
		if name == ".data" && need_i > 0 && need_i > file_sz {
			if std.exist("runtime_pclntab", owner.symTab) {
				grow = 1
			}
		}
		if grow == 1 {
			blk_sz = need_i
			need_as_u64<u64> = need_i.(u64)
			seg.sh_size = need_as_u64
		}
		if  name != ".bss" {
			if blk_sz != 0 {
				ss<i32> = blk_sz
				buf<u64*> = new ss
				// zero-fill grown tail
				zi<i32> = 0
				while zi < blk_sz {
					bp<i8*> = buf
					bp = bp + zi
					*bp = 0
					zi += 1
				}
				if file_sz != 0 {
					obj = this.ownerList[i]
					file_sz_u<u64> = file_sz.(u64)
					obj.getData(buf,seg.sh_offset,file_sz_u)
				}
				off_u32<u32> = size.(u32)
				sz_u32<u32> = blk_sz.(u32)
				this.blocks[] = newBlock(buf,off_u32,sz_u32)
			}
		}
		seg.sh_addr = *base + size
		size += blk_sz
	}
	*base = *base + size
	if name != ".bss" {
		*off += size
	}

	this.size = int(size)
}

Seglist::relocAddr(relAddr<u32>,type<u8>,symAddr<u32>,addend<i32>)
{
	utils.debug("Seglist::relocAddr ",this.baseAddr)

	baddr<u32>     = *this.baseAddr
	relOffset<u32> = relAddr - baddr

	b<Block> = null
	for(v<Block> : this.blocks){
		if v.offset <= relOffset && v.offset + v.size > relOffset {
			b = v
			break
		}
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
			if  *opcode == 0x8b {
				_reg<u8> = *modr - 0x05
				reg<u8> = _reg / 8
				*opcode = 0xc7
				*modr = 0xc0 + reg
			}
			*paddr = symAddr - addend
		}
		linux.R_X86_64_PC32  : 	*paddr = symAddr - relAddr + *paddr
		linux.R_X86_64_PLT32 :	*paddr = symAddr - relAddr + *paddr
		linux.R_X86_64_64    :    *paddr = symAddr - addend
		_  				   :    utils.debug("unknow rela")
	}
}

// Read u64 at VA into out; returns 1 on hit, 0 on miss.
Seglist::pcln_read_u64_into(va_u<u32>, out<u64*>){
	baddr_u<u32> = *this.baseAddr
	rel_u<u32> = va_u - baddr_u
	eight_u<u32> = 8
	for(v<Block> : this.blocks){
		if v.offset <= rel_u && rel_u + eight_u <= v.offset + v.size {
			base<i8*> = v.data
			off_i<i32> = (rel_u - v.offset).(i32)
			p<u64*> = base + off_i
			*out = *p
			return 1
		}
	}
	return 0
}

// Read i32 at VA into out; returns 1 on hit, 0 on miss.
Seglist::pcln_read_i32_into(va_u<u32>, out<i32*>){
	baddr_u<u32> = *this.baseAddr
	rel_u<u32> = va_u - baddr_u
	four_u<u32> = 4
	for(v<Block> : this.blocks){
		if v.offset <= rel_u && rel_u + four_u <= v.offset + v.size {
			base<i8*> = v.data
			off_i<i32> = (rel_u - v.offset).(i32)
			p<i32*> = base + off_i
			*out = *p
			return 1
		}
	}
	return 0
}
