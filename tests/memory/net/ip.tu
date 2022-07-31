

mem Ip
{
	u8  version:4
	u8  lhl:4
	u8  tos
	u16 totallen
	u16 identify
	u16 r:1
	u16 d:1
	u16 m:1
	u16 foffset:13
	u32 t1
	u64 t2
}