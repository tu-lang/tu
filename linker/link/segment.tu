use linux
use fmt

class Seglist
{
	baseAddr  = 0   # 分配基地址
	offset    = 0   # 合并后的文件偏移
	size	  = 0   # 合并后的大小
	begin  	  = 0   # 对齐前开始位置偏移
	ownerList = []  # array[ElfFile] 
	blocks	  = []  # array[Block]
}

# @param name string 段名	
# @param off 文件偏移地址
# @param base 加载基地址
Seglist::allocAddr(name,base<i32*>,off<i32*>)
{
	utils.debug("Seglist::allocAddr ",name,int(*off))
	this.begin = int(*off) # 记录文件前偏移
	# 虚拟地址对齐，让所有的段按照4k字节对其
	if  name != ".bss" {
		tmp<i32> = MEM_ALIGN - *base % MEM_ALIGN
		*base += tmp % MEM_ALIGN
	}
	# 偏移第一对齐，让一般段按照4字节对齐，文本段16字节对齐
	align<i32> = DISC_ALIGN
	if  name == ".text" {
		align = 16
	}
	temp_align<i32> = align - *off % align
	*off += temp_align % align

	# 使虚地址和偏移按照 4k摸去余
	*base = *base - *base % MEM_ALIGN + *off % MEM_ALIGN
	//累加地址和偏移
	this.baseAddr = int(*base)
	this.offset = int(*off)
	size<i32> = 0
	for( i = 0 ; i < std.len(this.ownerList) ; i += 1){
		# 对齐每个小段，按照4字节
		ts<i32> = DISC_ALIGN - size % DISC_ALIGN
		size += ts % DISC_ALIGN
		seg<linux.Elf64_Shdr> = this.ownerList[i].shdrTab[name]
		# 读取需要合并段段数据
		if  name != ".bss" {
			//申请数据缓存
			ss<i32> = seg.sh_size
			if seg.sh_size != 0 {
				buf<u64*> = new ss
				obj = this.ownerList[i]
				obj.getData(buf,seg.sh_offset,seg.sh_size)
				this.blocks[] = newBlock(buf,size,seg.sh_size)
			}
		}
		//修改每个文件中对应段的addr
		seg.sh_addr = *base + size
		size += seg.sh_size
	}
	#累加地址
	*base = *base + size
	# bss段不修改偏移
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
				# reg = (*modr - 0x05)/8
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