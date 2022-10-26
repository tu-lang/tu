use fmt

func test_i8_i32_mixed(){
	a<i8> = -5
	if a < 0 {} else os.die("-5 < 0")
	b<i32> = 5
	c<u8> = 14
	r<i32> = a + ( b % c)
	if r == 0 {} else os.die(" -5 + ( 5 % 15)  != 0")
	fmt.println("test_i_i32_mixed success")
}

func main(){
	test_i8_i32_mixed()
}