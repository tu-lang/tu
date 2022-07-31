
use fmt

//定义一些 limits 限制值
I8_MAX  I8_MIN  U8_MAX  U8_MIN
I16_MAX I16_MIN U16_MAX U16_MIN
I32_MAX I32_MIN U32_MAX U32_MIN
I64_MAX I64_MIN I64_MAX U64_MIN


// 测试 1字节 有无符号的溢出
func i8_u8(){
	a<i8> = 1
	fmt.assert(int(a),1)
	a = -127
	fmt.assert(int(a),-127)
	a = 128
	fmt.assert(int(a),-128)

	au<u8> = 1
	fmt.assert(int(au),1)
	au = -1
	fmt.assert(int(au),255)
	au = 255
	fmt.assert(int(au),255)
	au = 256
	fmt.assert(int(au),0)
	
	fmt.println("test i8 & u8  assign successful")	
}
func i16_u16()
{
	fmt.println("test I16 - U16 max&min ")
	a<i16> = *I16_MAX	fmt.assert(int(a),I16_MAX)
	a<i16> = *I16_MIN	fmt.assert(int(a),I16_MIN)

	a2<u16> = *U16_MAX	fmt.assert(int(a2),U16_MAX)
	a2<u16> = *U16_MIN	fmt.assert(int(a2),U16_MIN)
	fmt.println("test I16 - U16 max&min success")

}
func i32_u32()
{
	fmt.println("test I32 - U32 max&min")
	a<i32> = *I32_MAX	fmt.assert(int(a),I32_MAX)
	a<i32> = *I32_MIN	fmt.assert(int(a),I32_MIN)

	a2<u32> = *U32_MAX	fmt.assert(int(a2),U32_MAX)
	a2<u32> = *U32_MIN	fmt.assert(int(a2),U32_MIN)
	fmt.println("test I32 - U32 max&min success")
}
func i64_u64()
{
	fmt.println("test I64 - U64 max&min")
	a<i64> = *I64_MAX	fmt.assert(int(a),I64_MAX)
	a<i64> = *I64_MIN	fmt.assert(int(a),I64_MIN)

	//todo: a<u64> = *U64_MAX	fmt.assert(int(a),U64_MAX)
	//a<u64> = *U64_MIN	fmt.assert(int(a),U64_MIN)
	
	fmt.println("test I64 - U64 max&min success")

}

func init(){
	fmt.println("test I8 - U8 max&min")
	I8_MAX=127 						I8_MIN=-128 				 	U8_MAX=255 						U8_MIN=0 
	fmt.assert(I8_MAX,127) 			fmt.assert(I8_MIN,-128) 	 	fmt.assert(U8_MAX,255)			fmt.assert(U8_MIN,0)

	fmt.println("test I16 - U16 max&min")
	I16_MAX=32767 					I16_MIN=-32768 				 	U16_MAX=65535 					U16_MIN=0 
	fmt.assert(I16_MAX,32767) 		fmt.assert(I16_MIN,-32768) 	 	fmt.assert(U16_MAX,65535)		fmt.assert(U16_MIN,0)

	fmt.println("test I32 - U32 max&min")
	I32_MAX=2147483647 				I32_MIN=-2147483648 		 	U32_MAX=4294967295 				U32_MIN=0 
	fmt.assert(I32_MAX,2147483647) 	fmt.assert(I32_MIN,-2147483648) fmt.assert(U32_MAX,4294967295)	fmt.assert(U32_MIN,0)

	fmt.println("test I64 - U64 max&min")
	I64_MAX=9223372036854775807 	fmt.assert(I64_MAX,9223372036854775807,"i64_max") 	
	I64_MIN=-9223372036854775808 	fmt.assert(I64_MIN,-9223372036854775808,"i64_min") 	
	// TODO: U64_MAX=18446744073709551615 	fmt.assert(I64_MAX,18446744073709551615,"u64_max") 	
	U64_MIN=0						fmt.assert(U64_MIN,0) 
	fmt.println("Test i8 - u6 assign success")
}
func main(){
	init()
	i8_u8()
	i16_u16()
	i32_u32()
	i64_u64()
}