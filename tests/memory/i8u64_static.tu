
use fmt

//定义一些 limits 限制值
I8_MAX<i8>   I8_MIN<i8>   U8_MAX<u8>   U8_MIN<u8>

I16_MAX<i16> I16_MIN<i16> U16_MAX<u16> U16_MIN<u16>

I32_MAX<i32> I32_MIN<i32> U32_MAX<u32> U32_MIN<u32>

I64_MAX<i64> I64_MIN<i64> U64_MAX<u64> U64_MIN<u64>

func die(str){
	fmt.println(str)
	os.exit(-1)
}
func assertu(a<u64>,b<u64>,str){
	check<u8> = str
	if  a != b  {
		expr = "assert: " + int(a) + " != " + int(b)
		if  check != null {
			msg  = "warmsg: " + str
			fmt.println(msg)
		}
		os.exit(-1)
	}
}
func asserti(a<i64>,b<i64>,str){
	check<u8> = str
	if  a != b  {
		expr = "assert: " + int(a) + " != " + int(b)
		if  check != null {
			msg  = "warmsg: " + str
			fmt.println(msg)
		}
		os.exit(-1)
	}
}

// 测试 1字节 有无符号的溢出
func i8_u8(){
	fmt.println("test i8_u8")
	a<i8> = 1
	if  a != 1 {die("a != 1")}

	a = -127
	if  a != -127 {die("a != -127")}

	a = 128
	if  a != -128 {die("a != -128")}

	au<u8> = 1
	if  au != 1 {die("a != 1")}
	
	au = -1
	if  au != 255 {die("au != 255")}
	au = 255
	if  au != 255 {die("au != 255")}
	au = 256
	if  au != 0 {die("au != 0")}
	
	fmt.println("test i8 & u8  assign successful")	
}
func i16_u16()
{
	fmt.println("test I16 - U16 max&min ")
	a<i16> = I16_MAX	asserti(a,I16_MAX)
	a<i16> = I16_MIN	asserti(a,I16_MIN)

	a2<u16> = U16_MAX	assertu(a2,U16_MAX)
	a2<u16> = U16_MIN	assertu(a2,U16_MIN)
	fmt.println("test I16 - U16 max&min success")

}
func i32_u32()
{
	fmt.println("test I32 - U32 max&min")
	a<i32> = I32_MAX	asserti(a,I32_MAX)
	a<i32> = I32_MIN	asserti(a,I32_MIN)

	a2<u32> = U32_MAX	assertu(a2,U32_MAX)
	a2<u32> = U32_MIN	assertu(a2,U32_MIN)
	fmt.println("test I32 - U32 max&min success")
}
func i64_u64()
{
	fmt.println("test I64 - U64 max&min")
	a<i64> = I64_MAX	asserti(a,I64_MAX)
	a<i64> = I64_MIN	asserti(a,I64_MIN)

	a2<u64> = U64_MAX	assertu(a2,U64_MAX)
	a2<u64> = U64_MIN	assertu(a2,U64_MIN)
	fmt.println("test I64 - U64 max&min success")

}

func init(){
	fmt.println("test I8 - U8 max&min")
	I8_MAX=127 	 I8_MIN=-128 				 	U8_MAX=255 						U8_MIN=0 
	if  I8_MAX != 127 {die("i8_max != 127")}
	if  I8_MIN != -128 {die("i8_min != -128")}
	if  U8_MAX != 255 {die("u8_max != 255")}

	fmt.println("test I16 - U16 max&min")
	I16_MAX=32767 					I16_MIN=-32768 				 	U16_MAX=65535 					U16_MIN=0 
	if  I16_MAX != 32767 {die("u16_max != 32767")}
	if  I16_MIN != -32768 {die("i16_max != -32768")}
	if  U16_MAX != 65535 {die("u16_max != 65535")}


	fmt.println("test I32 - U32 max&min")
	I32_MAX=2147483647 				I32_MIN=-2147483648 		 	U32_MAX=4294967295 				U32_MIN=0 
	if  I32_MAX != 2147483647 {die("i32_max != 2147483647")}
	if  I32_MIN != -2147483648 {die("i32_min != -2147483648")}
	if  U32_MAX != 4294967295 {die("u32_max != 4294967295")}

	fmt.println("test I64 - U64 max&min")
	I64_MAX=9223372036854775807 	
	if  I64_MAX != 9223372036854775807 {die("i64_max != 9223372036854775807")}

	I64_MIN=-9223372036854775808 	
	if  I64_MIN != -9223372036854775808 {die("i64_min != -9223372036854775808")}
	
	U64_MAX=18446744073709551615 	
	if  U64_MAX != 18446744073709551615 {die("u64_max != 18446744073709551615")}
	fmt.println("test i8 - u6 assign success")
}
func main(){
	init()
	i8_u8()
	i16_u16()
	i32_u32()
	i64_u64()
}