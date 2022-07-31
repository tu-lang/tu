
use fmt
use os

mem Byte{
	i8 a1:1,a2:1,a3:1,a4:1,a5:1,a6:1,a7:1,a8:1
}
func assert(a,b,str){
	if  a != b  {
		fmt.println(a + " != " + b ,str)
		os.exit(-1)
	}
}
func byte_assign(b<Byte>){
	fmt.println("byte_assign test")
	a<u8*> = b
	// 1 0 0 0 0 0 0 0 => 1
	b.a1 = 1
	assert(1,int(*a),"test byte_assign failed u8 != 1")

	// 1 1 0 0 0 0 0 0 => 3
	b.a2 = 1
	assert(3,int(*a),"test byte_assign failed u8 != 3")

	// 1 1 1 0 0 0 0 0 => 7
	b.a3 = 1
	assert(7,int(*a),"test byte_assign failed u8 != 7")

	// 1 1 1 1 0 0 0 0 => 15
	b.a4 = 1
	assert(15,int(*a),"test byte_assign failed u8 != 15")

	// 1 1 1 1 1 0 0 0 => 31
	b.a5 = 1
	assert(31,int(*a),"test byte_assign failed u8 != 31")

	// 1 1 1 1 1 1 0 0 => 63
	b.a6 = 1
	assert(63,int(*a),"test byte_assign failed u8 != 63")

	// 1 1 1 1 1 1 1 0 => 127
	b.a7 = 1
	assert(127,int(*a),"test byte_assign failed u8 != 127")

	// 1 1 1 1 1 1 1 1 => 255
	b.a8 = 1
	assert(255,int(*a),"test byte_assign failed u8 != 255")

	fmt.println("test byte read write success")
}

func test_unsigned(b<Byte>){
	a<u8*> = b
	assert(255,int(*a),"test failed u8 != 255")

	a2<i8*> = b
	assert(-1,int(*a2),"test failed i8 != -1")

	fmt.println("test byte unsigned success")
}
func main(){
	b<Byte> = new Byte
	byte_assign(b)
	test_unsigned(b)

	fmt.println("test byte success")

}