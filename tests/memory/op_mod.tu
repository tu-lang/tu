use fmt

mem Pointer{
	i8 up
}
// i8测试
func i8_test(){
	fmt.println("i8 test")
	// var test
	t<i8> = 8
	t %= 10
	fmt.assert(int(t),8)
	t = t % 8
	fmt.assert(int(t),0)
	t = 8
	t = t % 7
	fmt.assert(int(t),1)
	fmt.println("i8 var test success")

	// member test
	p<Pointer> = new Pointer
	p.up = 8
	p.up %= 10
	fmt.assert(int(p.up),8,"8 != 8")
	p.up %= 10
	fmt.assert(int(p.up),8)
	p.up = p.up % 8
	fmt.assert(int(p.up),0)
	p.up = 8
	p.up = p.up % 7
	fmt.assert(int(p.up),1)
	fmt.println("i8 test success")
}

mem Pu8{
	u8 p
}
func u8_test(){
	fmt.println("u8 test ")
	t<u8> = 200
	t %= 201
	fmt.assert(int(t),200)

	t = t % 190
	fmt.assert(int(t),10)

	t = 200
	t = t % 200
	fmt.assert(int(t),0)

	t2<Pu8> = new Pu8

	t2.p = 200
	t2.p %= 201
	fmt.assert(int(t2.p),200)

	t2.p = t2.p % 190
	fmt.assert(int(t2.p),10)

	t2.p = 200
	t2.p = t2.p % 200
	fmt.assert(int(t2.p),0)

	fmt.println("u8 test success")
}
func main(){
	i8_test()
	u8_test()
}