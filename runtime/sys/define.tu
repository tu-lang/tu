_EACCES<i64> = 13
_EINVAL<i64> =  22

ERROR<i64>   = -1
OK<i64>   	 = 0
_EAGAIN<i64> = 0xb
_ENOMEM<i64> = 0xc

_PROT_NONE<i64> =  0x0
_PROT_READ<i64> = 0x1
_PROT_WRITE<i64> = 0x2
_PROT_EXEC<i64> = 0x4

_MAP_ANON<i64> = 0x20
_MAP_PRIVATE<i64> = 0x2
_MAP_FIXED<i64> = 0x10

_MADV_DONTNEED<i64> = 0x4
_MADV_FREE<i64>     = 0x8
_MADV_HUGEPAGE<i64> = 0xe
_MADV_NOHUGEPAGE<i64> = 0xf

pageSize<i64>   = 8192
persistentChunkSize<i64> =  262144 
ptrSize<i64>	= 8
physPageSize<u64> = 0
HugePageSize<u64> = 2097152
True<i64> = 1

fixAllocChunk<i64> 		= 16384

deBruijn64<i64>			= 0x0218a392cd3d5dbf
deBruijnIdx64<u8:64> = [
	0,  1,  2,  7,  3,  13, 8,  19,
	4,  25, 14, 28, 9,  34, 20, 40,
	5,  17, 26, 38, 15, 46, 29, 48,
	10, 31, 35, 54, 21, 50, 41, 57,
	63, 6,  12, 18, 24, 27, 33, 39,
	16, 37, 45, 47, 30, 53, 49, 56,
	62, 11, 23, 32, 36, 44, 52, 55,
	61, 22, 43, 51, 60, 42, 59, 58,
]
