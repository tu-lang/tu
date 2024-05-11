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
Seglist::allocAddr(name,base<i32*>,off<i32*>)
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
	for( i = 0 ; i < std.len(this.ownerList) ; i += 1){
		ts<i32> = DISC_ALIGN - size % DISC_ALIGN
		size += ts % DISC_ALIGN
		seg<linux.Elf64_Shdr> = this.ownerList[i].shdrTab[name]
		if  name != ".bss" {
			ss<i32> = seg.sh_size
			if seg.sh_size != 0 {
				buf<u64*> = new ss
				obj = this.ownerList[i]
				obj.getData(buf,seg.sh_offset,seg.sh_size)
				this.blocks[] = newBlock(buf,size,seg.sh_size)
			}
		}
		seg.sh_addr = *base + size
		size += seg.sh_size
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
				// reg = (*modr - 0x05)/8
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