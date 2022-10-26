use fmt
use os
use std
use string

Null<i64> = 0
True<i64> = 1
False<i64> = 0

EI_CLASS<i64> = 4
EI_DATA<i64>  = 5
EI_VERSION<i64> = 6
ELFCLASS64<i64> = 2
ELFDATA2LSB<i64> = 	1
EV_CURRENT<i64>	= 1	
//OPTIMIZE: <*>=
U8<i64> = 1
I8<i64> = 1
U16<i64> = 2
U32<i64> = 4
U64<i64> = 8

mem Reader {
    i8* buffer
    i32 len,offset
}

mem Row {
    u64 address
    i32 file,line
}
mem PcData {
	u64 address
	i32 line
	string.String* filename
}


mem LineHeader:pack{
	u32 total
	u16 version
	u32 length
	u8	m_length
	u8  is_stmt
	i8  base
	u8  range
	u8  opcode_base
}
mem Lines {
	Reader 	   reader
	i32 	   file_offset
    std.Array* files //[string]
    std.Array* rows  // [Row]
}