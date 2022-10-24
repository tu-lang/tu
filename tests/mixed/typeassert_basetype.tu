use fmt

func test_int(){
	num = 376.(i8)
	_tmp<i32> = 376

	if _tmp == num {} else os.die("num should be 376 static")

	if int(num) == 376 {} else os.die("num should be 376")

	fn = func(v<i32>){
		if v == 444 {} else os.die("v should b 444")
	}
	fn(444.(i32))
	fmt.println("test_int success")
}
func test_char(){
	c = 'd'.(i8)
	_t<i32> = 'd'
	if _t == c {} else os.die("c != d")

	fn = func(v<i32>){
		if v == 'x'  {} else os.die(" v != x")
	}
	fn('x'.(i8))
	fmt.println("test_char success")
}
func test_string(){
	str = "45ss54".(i8)
	if string.new(str) == "45ss54" {} else os.die("str != 45ss54")
	fmt.println("test string success")
}
func main(){
	test_int()
	test_char()
	test_string()
}