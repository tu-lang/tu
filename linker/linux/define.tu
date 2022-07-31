
# 全局变量定义
ET_NONE<i32> = 0
ET_REL<i32>  = 1 
ET_EXEC<i32> = 2 
ET_DYN<i32>  = 3
ET_CORE<i32> = 4
ET_NUM<i32>  = 5
ET_LOOS<i32> = 0xfe00
ET_HIOS<i32> = 0xfeff
ET_LOPROC<i32> = 0xff00
ET_HIPROC<i32> = 0xffff

PF_X<i32>    = 1
PF_W<i32>    = 2
PF_R<i32>    = 4
PF_MASKOS<i32> =   0x0ff00000
PF_MASKPROC<i32> = 0xf0000000

SHN_UNDEF<i32>  = 0
SHN_COMMON<i32> = 	0xfff2
SHN_ABS<i32>    =		0xfff1

R_X86_64_PC32<i32> = 2
R_X86_64_PLT32<i32> = 4
R_X86_64_64<i32> = 1

STB_LOCAL<i32>  = 0
STB_GLOBAL<i32> = 1
STT_OBJECT<i32> = 1
STT_FUNC<i32>   = 2

SHF_WRITE<i32>  = 1
SHF_ALLOC<i32>  = 2
SHF_EXECINSTR<i32> = 4

EM_X86_64<i32>  = 62
EV_NONE<i32>    = 0
EV_CURRENT<i32> = 1
EV_NUM<i32>     = 2

PT_NULL<i32>	=	0
PT_LOAD<i32>    =	1		
PT_DYNAMIC<i32> = 2		
PT_INTERP<i32>  = 3		
PT_NOTE<i32>    = 4		
PT_SHLIB<i32>   = 5		
PT_PHDR<i32>    = 6	


SHT_PROGBITS<i32> = 1		
SHT_SYMTAB<i32>   = 2
SHT_STRTAB<i32>   = 3
SHT_NOBITS<i32>   = 8


func ELF64_R_SYM(i<u64>)	{
	return i >> 32
}
func ELF32_ST_BIND(val<u8>){
	return val >> 4
}
func ELF64_ST_BIND(val){
	return ELF32_ST_BIND(val)
}
func ELF64_ST_TYPE(val){
	return val & 0xf
}
func ELF64_R_TYPE(val<i64>){
	return val & 0xffffffff
}